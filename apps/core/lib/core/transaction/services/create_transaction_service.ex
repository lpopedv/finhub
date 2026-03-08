defmodule Core.Transaction.Services.CreateTransactionService do
  @moduledoc """
  Service for creating transactions.

  This service handles the creation of a new transaction by taking a validated
  `CreateTransactionCommand` and persisting it to the database as a `Transaction` schema.
  """

  alias Core.Repo
  alias Core.Schemas.Transaction
  alias Core.Transaction.Commands.CreateTransactionCommand

  @spec execute(CreateTransactionCommand.t()) ::
          {:ok, Transaction.t()} | {:error, Ecto.Changeset.t()}
  def execute(%CreateTransactionCommand{} = command),
    do:
      %{
        user_id: command.user_id,
        category_id: command.category_id,
        name: command.name,
        value_in_cents: command.value_in_cents,
        is_fixed: command.is_fixed,
        date: command.date
      }
      |> Transaction.changeset()
      |> Repo.insert()
end
