defmodule Core.TransactionType do
  @moduledoc """
  Encapsulates the possible types of a transaction.
  """

  @types [:expense, :income]

  @type t :: :expense | :income

  @doc """
  Returns the list of transaction types.
  """
  @spec all() :: [t()]
  def all, do: @types
end
