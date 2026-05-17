defmodule Core.Conversation.Ports.GenerateResponsePort do
  @moduledoc """
  Port for generating AI responses in conversations.

  Defines the interface that any LLM adapter must implement.
  The active adapter is resolved at compile time via config, allowing
  the production adapter (OpenRouter) to be swapped for a stub in tests
  without changing application code.

  The `on_delta` callback is called by the adapter for each streamed
  token, decoupling the transport (SSE) from the broadcast mechanism
  (PubSub) defined by the caller.
  """

  @adapter Application.compile_env!(:core, [__MODULE__, :adapter])

  @type result :: %{
          content: String.t(),
          input_tokens: non_neg_integer(),
          cached_input_tokens: non_neg_integer(),
          output_tokens: non_neg_integer()
        }

  @callback model() :: String.t()

  @callback generate_response(
              messages :: [map()],
              on_delta :: (String.t() -> :ok)
            ) :: {:ok, result()} | {:error, term()}

  @spec model() :: String.t()
  def model, do: @adapter.model()

  @spec generate_response(messages :: [map()], on_delta :: (String.t() -> :ok)) ::
          {:ok, result()} | {:error, term()}
  def generate_response(messages, on_delta) do
    @adapter.generate_response(messages, on_delta)
  end
end
