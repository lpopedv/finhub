defmodule Core.Adapters.Conversation.GenerateResponsePort.Stub do
  @moduledoc false

  @behaviour Core.Conversation.Ports.GenerateResponsePort

  @impl Core.Conversation.Ports.GenerateResponsePort
  def model, do: "stub/model"

  @impl Core.Conversation.Ports.GenerateResponsePort
  def generate_response(_messages, on_delta) do
    on_delta.("Hello! ")
    on_delta.("How can I help?")

    {:ok,
     %{
       content: "Hello! How can I help?",
       input_tokens: 10,
       cached_input_tokens: 0,
       output_tokens: 8
     }}
  end
end
