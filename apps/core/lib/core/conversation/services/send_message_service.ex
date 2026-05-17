defmodule Core.Conversation.Services.SendMessageService do
  @moduledoc """
  Service for sending a user message in a conversation.

  Validates conversation ownership, inserts the user message, updates the
  conversation timestamp, and enqueues `GenerateResponseWorker` — all within
  a single database transaction so that a failed enqueue never leaves an
  orphaned message.

  Returns the inserted user `Message` on success.
  """

  import Ecto.Query

  alias Core.Conversation.Commands.SendMessageCommand
  alias Core.Conversation.Workers.GenerateResponseWorker
  alias Core.Repo
  alias Core.Schemas.Conversation
  alias Core.Schemas.Message

  @spec execute(SendMessageCommand.t()) ::
          {:ok, Message.t()}
          | {:error, :conversation_not_found}
          | {:error, Ecto.Changeset.t()}
  def execute(%SendMessageCommand{} = command) do
    with {:ok, _conversation} <- fetch_conversation(command) do
      Repo.transact(fn ->
        with {:ok, user_message} <- insert_user_message(command),
             :ok <- update_conversation_timestamp(command.conversation_id),
             {:ok, _job} <- enqueue_job(command.conversation_id, user_message.id) do
          {:ok, user_message}
        end
      end)
    end
  end

  defp fetch_conversation(%SendMessageCommand{conversation_id: id, user_id: user_id}) do
    queryable =
      from(c in Conversation,
        where: c.id == ^id and c.user_id == ^user_id and c.active == true
      )

    case Repo.one(queryable) do
      conversation when not is_nil(conversation) -> {:ok, conversation}
      nil -> {:error, :conversation_not_found}
    end
  end

  defp insert_user_message(command),
    do:
      %{
        conversation_id: command.conversation_id,
        role: :user,
        status: :completed,
        content: command.content
      }
      |> Message.changeset()
      |> Repo.insert()

  defp update_conversation_timestamp(conversation_id) do
    now = DateTime.utc_now()

    queryable = from(c in Conversation, where: c.id == ^conversation_id)

    case Repo.update_all(queryable, set: [last_message_at: now, updated_at: now]) do
      {1, _} -> :ok
      _ -> {:error, :conversation_update_failed}
    end
  end

  defp enqueue_job(conversation_id, user_message_id),
    do:
      %{
        conversation_id: conversation_id,
        user_message_id: user_message_id
      }
      |> GenerateResponseWorker.new()
      |> Oban.insert()
end
