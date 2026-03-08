defmodule Core.FixedTransaction.Services.CreateFixedTransactionService do
  @moduledoc """
  Service for creating a fixed transaction rule.

  Takes a validated `CreateFixedTransactionCommand` and persists it
  to the database as a `FixedTransaction` schema.
  """

  alias Core.FixedTransaction.Commands.CreateFixedTransactionCommand
  alias Core.Repo
  alias Core.Schemas.FixedTransaction

  @spec execute(CreateFixedTransactionCommand.t()) ::
          {:ok, FixedTransaction.t()} | {:error, Ecto.Changeset.t()}
  def execute(%CreateFixedTransactionCommand{} = command),
    do:
      %{
        user_id: command.user_id,
        category_id: command.category_id,
        name: command.name,
        value_in_cents: command.value_in_cents,
        day_of_month: command.day_of_month
      }
      |> FixedTransaction.changeset()
      |> Repo.insert()
end
