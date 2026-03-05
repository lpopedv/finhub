defmodule Core.Transaction.Services.UpdateTransactionService do
  @moduledoc """
  Service for updating an existing transaction.

  Accepts the transaction's ID and a map of attributes to update. Returns
  `{:error, :not_found}` if no transaction exists with the given ID.
  """

  alias Core.Repo
  alias Core.Schemas.Transaction

  @spec execute(String.t(), map()) ::
          {:ok, Transaction.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def execute(id, params) do
    with {:ok, transaction} <- get_transaction(id),
         do:
           transaction
           |> Transaction.changeset(params)
           |> Repo.update()
  end

  defp get_transaction(id) do
    case Repo.get(Transaction, id) do
      nil -> {:error, :not_found}
      transaction -> {:ok, transaction}
    end
  end
end
