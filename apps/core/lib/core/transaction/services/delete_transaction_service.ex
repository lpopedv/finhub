defmodule Core.Transaction.Services.DeleteTransactionService do
  @moduledoc """
  Service for deleting a transaction by ID.

  Returns `{:error, :not_found}` if no transaction exists with the given ID.
  """

  alias Core.Repo
  alias Core.Schemas.Transaction

  @spec execute(String.t()) :: {:ok, Transaction.t()} | {:error, :not_found}
  def execute(id) do
    with {:ok, transaction} <- get_transaction(id), do: Repo.delete(transaction)
  end

  defp get_transaction(id) do
    case Repo.get(Transaction, id) do
      nil -> {:error, :not_found}
      transaction -> {:ok, transaction}
    end
  end
end
