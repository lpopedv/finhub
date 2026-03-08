defmodule Core.FixedTransaction.Services.DeleteFixedTransactionService do
  @moduledoc """
  Service for deleting a fixed transaction rule by ID.

  Returns `{:error, :not_found}` if no fixed transaction exists with the given ID.
  When deleted, associated transactions have their `fixed_transaction_id` set to nil.
  """

  alias Core.Repo
  alias Core.Schemas.FixedTransaction

  @spec execute(String.t()) :: {:ok, FixedTransaction.t()} | {:error, :not_found}
  def execute(id) do
    with {:ok, fixed_transaction} <- get_fixed_transaction(id),
         do: Repo.delete(fixed_transaction)
  end

  defp get_fixed_transaction(id) do
    case Repo.get(FixedTransaction, id) do
      nil -> {:error, :not_found}
      fixed_transaction -> {:ok, fixed_transaction}
    end
  end
end
