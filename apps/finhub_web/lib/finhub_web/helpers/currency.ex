defmodule FinhubWeb.Helpers.Currency do
  @moduledoc "Formatting helpers for monetary values stored as integer cents."

  @spec format_brl(integer()) :: String.t()
  def format_brl(cents),
    do:
      "R$ #{div(cents, 100)},#{rem(cents, 100) |> Integer.to_string() |> String.pad_leading(2, "0")}"
end
