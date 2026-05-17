defmodule Core.HTTP do
  @moduledoc """
  Custom exceptions to support HTTP errors.
  """

  defmodule ResponseError do
    defexception [:message, :error_response]

    @impl Exception
    def exception(%Req.Response{} = error_response) do
      %__MODULE__{
        message:
          "Received a HTTP Error Response (Status: #{error_response.status}).\n#{inspect(error_response)}",
        error_response: error_response
      }
    end
  end

  defmodule FailedRequestError do
    defexception [:message, :reason]

    @impl Exception
    def exception(%Req.TransportError{} = error) do
      %__MODULE__{
        message: "HTTP Request Failed!\nReason: #{Exception.message(error)}",
        reason: error.reason
      }
    end

    def exception(reason) do
      %__MODULE__{
        message: "HTTP Request Failed!\nReason: #{inspect(reason)}",
        reason: reason
      }
    end
  end
end
