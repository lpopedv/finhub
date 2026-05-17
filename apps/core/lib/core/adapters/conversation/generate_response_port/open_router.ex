defmodule Core.Adapters.Conversation.GenerateResponsePort.OpenRouter do
  @moduledoc """
  OpenRouter adapter for `GenerateResponsePort`.

  Uses the OpenAI-compatible chat completions API with SSE streaming.
  Each token delta is forwarded to the `on_delta` callback as it arrives.
  Token usage is extracted from the final SSE chunk via `stream_options: include_usage`.

  The `plug:` config key is used only in tests to intercept HTTP calls via
  `Req.Test` without hitting the real API.
  """

  @behaviour Core.Conversation.Ports.GenerateResponsePort

  @empty_result %{content: "", input_tokens: 0, cached_input_tokens: 0, output_tokens: 0}

  @impl Core.Conversation.Ports.GenerateResponsePort
  def model, do: config()[:model]

  @impl Core.Conversation.Ports.GenerateResponsePort
  def generate_response(messages, on_delta) do
    body = %{
      model: config()[:model],
      messages: messages,
      stream: true,
      stream_options: %{include_usage: true}
    }

    case Req.post(http_client(),
           url: "/api/v1/chat/completions",
           json: body,
           into: stream_into(on_delta)
         ) do
      {:ok, %Req.Response{status: 200, body: result}} when is_map(result) -> {:ok, result}
      {:ok, %Req.Response{status: 200}} -> {:ok, @empty_result}
      {:ok, %Req.Response{} = resp} -> raise Core.HTTP.ResponseError, resp
      {:error, %Req.TransportError{} = error} -> raise Core.HTTP.FailedRequestError, error
    end
  end

  defp stream_into(on_delta) do
    fn {:data, chunk}, {req, resp} ->
      acc = if is_map(resp.body), do: resp.body, else: @empty_result
      {:cont, {req, %{resp | body: parse_chunk(chunk, acc, on_delta)}}}
    end
  end

  defp parse_chunk(chunk, acc, on_delta),
    do:
      chunk
      |> String.split("\n")
      |> Enum.filter(&String.starts_with?(&1, "data: "))
      |> Enum.map(&String.replace_prefix(&1, "data: ", ""))
      |> Enum.reject(&(&1 == "[DONE]"))
      |> Enum.reduce(acc, &parse_event(&1, &2, on_delta))

  defp parse_event(data, acc, on_delta) do
    case JSON.decode(data) do
      {:ok, event} -> apply_event(event, acc, on_delta)
      {:error, _} -> acc
    end
  end

  defp apply_event(event, acc, on_delta) do
    delta = get_in(event, ["choices", Access.at(0), "delta", "content"]) || ""

    acc
    |> maybe_broadcast(delta, on_delta)
    |> maybe_apply_usage(event["usage"])
  end

  defp maybe_broadcast(acc, "", _on_delta), do: acc

  defp maybe_broadcast(acc, delta, on_delta) do
    on_delta.(delta)
    %{acc | content: acc.content <> delta}
  end

  defp maybe_apply_usage(acc, nil), do: acc

  defp maybe_apply_usage(acc, usage) do
    %{
      acc
      | input_tokens: usage["prompt_tokens"] || 0,
        cached_input_tokens: get_in(usage, ["prompt_tokens_details", "cached_tokens"]) || 0,
        output_tokens: usage["completion_tokens"] || 0
    }
  end

  defp http_client do
    config = config()

    Req.new(
      base_url: "https://openrouter.ai",
      headers: [{"authorization", "Bearer #{config[:api_key]}"}],
      receive_timeout: config[:timeout] || 120_000,
      plug: config[:plug]
    )
  end

  defp config, do: Application.fetch_env!(:core, __MODULE__)
end
