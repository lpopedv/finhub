defmodule Core.Adapters.Conversation.GenerateResponsePort.OpenRouterTest do
  use ExUnit.Case, async: true

  alias Core.Adapters.Conversation.GenerateResponsePort.OpenRouter

  @moduletag :capture_log

  setup do
    config = Application.fetch_env!(:core, OpenRouter)
    %{config: config}
  end

  describe "model/0" do
    test "returns the configured model", %{config: config} do
      assert OpenRouter.model() == config[:model]
    end
  end

  describe "generate_response/2" do
    test "streams deltas and returns aggregated result", %{config: config} do
      sse_body = """
      data: {"choices":[{"delta":{"content":"Hello"},"finish_reason":null}]}

      data: {"choices":[{"delta":{"content":" world"},"finish_reason":null}]}

      data: {"choices":[{"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":10,"completion_tokens":2,"prompt_tokens_details":{"cached_tokens":3}}}

      data: [DONE]

      """

      Req.Test.stub(OpenRouter, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/api/v1/chat/completions"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request_body = Jason.decode!(body)

        assert request_body["model"] == config[:model]
        assert request_body["stream"] == true
        assert request_body["stream_options"] == %{"include_usage" => true}

        [auth_header] = Plug.Conn.get_req_header(conn, "authorization")
        assert auth_header == "Bearer #{config[:api_key]}"

        conn
        |> Plug.Conn.put_resp_content_type("text/event-stream")
        |> Plug.Conn.send_resp(200, sse_body)
      end)

      deltas = []
      on_delta = fn token -> send(self(), {:delta, token}) end

      assert {:ok, result} =
               OpenRouter.generate_response(
                 [%{"role" => "user", "content" => "Hello"}],
                 on_delta
               )

      assert result.content == "Hello world"
      assert result.input_tokens == 10
      assert result.cached_input_tokens == 3
      assert result.output_tokens == 2

      assert_received {:delta, "Hello"}
      assert_received {:delta, " world"}

      _ = deltas
    end

    test "includes system message when provided" do
      sse_body = """
      data: {"choices":[{"delta":{"content":"ok"},"finish_reason":"stop"}],"usage":{"prompt_tokens":5,"completion_tokens":1,"prompt_tokens_details":{"cached_tokens":0}}}

      data: [DONE]

      """

      Req.Test.stub(OpenRouter, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        request_body = Jason.decode!(body)

        [system, user] = request_body["messages"]
        assert system["role"] == "system"
        assert system["content"] == "You are a financial assistant."
        assert user["role"] == "user"

        conn
        |> Plug.Conn.put_resp_content_type("text/event-stream")
        |> Plug.Conn.send_resp(200, sse_body)
      end)

      messages = [
        %{"role" => "system", "content" => "You are a financial assistant."},
        %{"role" => "user", "content" => "Hello"}
      ]

      assert {:ok, result} = OpenRouter.generate_response(messages, fn _ -> :ok end)
      assert result.content == "ok"
    end

    test "raises ResponseError on non-200 HTTP status" do
      Req.Test.stub(OpenRouter, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(401, Jason.encode!(%{"error" => "Unauthorized"}))
      end)

      assert_raise Core.HTTP.ResponseError, fn ->
        OpenRouter.generate_response([%{"role" => "user", "content" => "Hi"}], fn _ -> :ok end)
      end
    end

    test "raises FailedRequestError on transport error" do
      Req.Test.stub(OpenRouter, fn conn ->
        Req.Test.transport_error(conn, :timeout)
      end)

      assert_raise Core.HTTP.FailedRequestError, fn ->
        OpenRouter.generate_response([%{"role" => "user", "content" => "Hi"}], fn _ -> :ok end)
      end
    end

    test "ignores malformed SSE lines gracefully" do
      sse_body = """
      data: not-valid-json

      data: {"choices":[{"delta":{"content":"ok"},"finish_reason":"stop"}],"usage":{"prompt_tokens":1,"completion_tokens":1,"prompt_tokens_details":{"cached_tokens":0}}}

      data: [DONE]

      """

      Req.Test.stub(OpenRouter, fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("text/event-stream")
        |> Plug.Conn.send_resp(200, sse_body)
      end)

      assert {:ok, result} = OpenRouter.generate_response([], fn _ -> :ok end)
      assert result.content == "ok"
    end
  end
end
