defmodule Core.Conversation.Workers.GenerateResponseWorker do
  @moduledoc """
  Oban worker that generates an AI response for a given conversation.

  Loads the conversation history and the agent's active system prompt, creates
  a pending assistant message, then delegates streaming to `GenerateResponsePort`.
  Each token delta is broadcast via PubSub so the LiveView can update in real time.
  On completion the assistant message is updated with the full content and token
  counts, and a `LlmUsageHistory` record is appended.

  Implements idempotency: on retry, reuses any existing pending assistant message
  instead of creating a new one. Marks the message as `:error` only on the last
  attempt so intermediate retries remain invisible to the user.
  """

  use Oban.Worker, queue: :ai, max_attempts: 3

  import Ecto.Query

  alias Core.Conversation.Ports.GenerateResponsePort
  alias Core.Repo
  alias Core.Schemas.AiAgentPrompt
  alias Core.Schemas.Conversation
  alias Core.Schemas.LlmUsageHistory
  alias Core.Schemas.Message

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"conversation_id" => conversation_id, "user_message_id" => _},
        attempt: attempt,
        max_attempts: max_attempts
      }) do
    last_attempt? = attempt >= max_attempts

    with {:ok, conversation} <- fetch_conversation(conversation_id),
         {:ok, assistant_message} <-
           get_or_create_assistant_message(conversation_id, GenerateResponsePort.model()) do
      broadcast(conversation_id, {:ai_message_created, assistant_message})
      do_generate(conversation, assistant_message, last_attempt?)
    end
  end

  defp do_generate(conversation, assistant_message, last_attempt?) do
    conversation_id = conversation.id
    message_id = assistant_message.id

    history = build_history(conversation_id)
    system_prompt = fetch_system_prompt(conversation)
    api_messages = build_api_messages(history, system_prompt)
    on_delta = fn token -> broadcast(conversation_id, {:ai_token, message_id, token}) end

    with {:ok, result} <- GenerateResponsePort.generate_response(api_messages, on_delta),
         {:ok, completed} <- complete_message(assistant_message, result),
         :ok <- record_usage(conversation, completed, result) do
      broadcast(conversation_id, {:ai_completed, completed})
      :ok
    else
      {:error, reason} ->
        if last_attempt? do
          mark_as_error(message_id)
          broadcast(conversation_id, {:ai_error, message_id})
        end

        {:error, reason}
    end
  end

  defp fetch_conversation(conversation_id) do
    case Repo.get(Conversation, conversation_id) do
      conversation when not is_nil(conversation) -> {:ok, conversation}
      nil -> {:error, :conversation_not_found}
    end
  end

  defp get_or_create_assistant_message(conversation_id, model) do
    queryable =
      from m in Message,
        where:
          m.conversation_id == ^conversation_id and
            m.role == :assistant and
            m.status == :pending,
        order_by: [desc: m.inserted_at],
        limit: 1

    case Repo.one(queryable) do
      message when not is_nil(message) -> {:ok, message}
      nil -> insert_assistant_message(conversation_id, model)
    end
  end

  defp insert_assistant_message(conversation_id, model) do
    %{
      conversation_id: conversation_id,
      role: :assistant,
      status: :pending,
      content: "",
      llm_model: model
    }
    |> Message.changeset()
    |> Repo.insert()
  end

  defp build_history(conversation_id) do
    queryable =
      from m in Message,
        where: m.conversation_id == ^conversation_id and m.status == :completed,
        order_by: [asc: m.inserted_at],
        select: {m.role, m.content}

    queryable
    |> Repo.all()
    |> Enum.map(fn {role, content} -> %{"role" => to_string(role), "content" => content} end)
  end

  defp fetch_system_prompt(%Conversation{ai_agent_id: nil}), do: nil

  defp fetch_system_prompt(%Conversation{ai_agent_id: agent_id}) do
    queryable =
      from p in AiAgentPrompt,
        where: p.ai_agent_id == ^agent_id and p.active == true,
        select: p.content

    Repo.one(queryable)
  end

  defp build_api_messages(history, nil), do: history

  defp build_api_messages(history, system_prompt),
    do: [%{"role" => "system", "content" => system_prompt} | history]

  defp complete_message(assistant_message, result),
    do:
      assistant_message
      |> Message.changeset(%{
        content: result.content,
        status: :completed,
        input_tokens: result.input_tokens,
        cached_input_tokens: result.cached_input_tokens,
        output_tokens: result.output_tokens
      })
      |> Repo.update()

  defp mark_as_error(message_id) do
    queryable = from m in Message, where: m.id == ^message_id
    Repo.update_all(queryable, set: [status: :error, updated_at: DateTime.utc_now()])
    :ok
  end

  defp record_usage(conversation, message, result) do
    changeset =
      LlmUsageHistory.changeset(%{
        user_id: conversation.user_id,
        conversation_id: conversation.id,
        message_id: message.id,
        model: message.llm_model,
        input_tokens: result.input_tokens,
        cached_input_tokens: result.cached_input_tokens,
        output_tokens: result.output_tokens
      })

    case Repo.insert(changeset) do
      {:ok, _} -> :ok
      {:error, _} -> :ok
    end
  end

  defp broadcast(conversation_id, event) do
    Phoenix.PubSub.broadcast(Core.PubSub, "conversation:#{conversation_id}", event)
    :ok
  end
end
