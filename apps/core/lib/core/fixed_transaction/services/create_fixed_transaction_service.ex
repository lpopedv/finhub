defmodule Core.FixedTransaction.Services.CreateFixedTransactionService do
  @moduledoc """
  Service for creating a fixed transaction rule.

  Uses `Repo.transact/1` to atomically insert the `FixedTransaction` record and
  the corresponding `Transaction` for the current month, so the user immediately
  sees the expense reflected. Future months are handled by the daily worker.

  The transaction name is formatted as "name - MM/YYYY" (e.g. "Aluguel - 03/2026").
  """

  alias Core.FixedTransaction.Commands.CreateFixedTransactionCommand
  alias Core.Repo
  alias Core.Schemas.FixedTransaction
  alias Core.Transaction.Commands.CreateTransactionCommand
  alias Core.Transaction.Services.CreateTransactionService

  @spec execute(CreateFixedTransactionCommand.t()) ::
          {:ok, FixedTransaction.t()} | {:error, Ecto.Changeset.t()}
  def execute(%CreateFixedTransactionCommand{} = command) do
    today = Date.utc_today()

    Repo.transact(fn ->
      with {:ok, fixed_transaction} <- insert_fixed_transaction(command),
           {:ok, _transaction} <-
             CreateTransactionService.execute(transaction_command(fixed_transaction, today)),
           do: {:ok, fixed_transaction}
    end)
  end

  defp insert_fixed_transaction(command),
    do:
      %{
        user_id: command.user_id,
        category_id: command.category_id,
        name: command.name,
        value_in_cents: command.value_in_cents,
        day_of_month: command.day_of_month,
        type: command.type
      }
      |> FixedTransaction.changeset()
      |> Repo.insert()

  defp transaction_command(fixed_transaction, today),
    do:
      CreateTransactionCommand.build!(%{
        user_id: fixed_transaction.user_id,
        category_id: fixed_transaction.category_id,
        fixed_transaction_id: fixed_transaction.id,
        name: "#{fixed_transaction.name} - #{Calendar.strftime(today, "%m/%Y")}",
        value_in_cents: fixed_transaction.value_in_cents,
        date: Date.new!(today.year, today.month, fixed_transaction.day_of_month),
        type: fixed_transaction.type
      })
end
