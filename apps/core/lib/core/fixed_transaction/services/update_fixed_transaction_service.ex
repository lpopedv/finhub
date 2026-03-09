defmodule Core.FixedTransaction.Services.UpdateFixedTransactionService do
  @moduledoc """
  Service for updating an existing fixed transaction rule.

  Accepts the fixed transaction's ID and a map of attributes to update.
  Returns `{:error, :not_found}` if no fixed transaction exists with the given ID.
  """

  alias Core.Repo
  alias Core.Schemas.FixedTransaction

  @spec execute(String.t(), map()) ::
          {:ok, FixedTransaction.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def execute(id, params) do
    with {:ok, fixed_transaction} <- get_fixed_transaction(id),
         do:
           fixed_transaction
           |> FixedTransaction.changeset(params)
           |> Repo.update()
  end

  defp get_fixed_transaction(id) do
    case Repo.get(FixedTransaction, id) do
      nil -> {:error, :not_found}
      fixed_transaction -> {:ok, fixed_transaction}
    end
  end
end
