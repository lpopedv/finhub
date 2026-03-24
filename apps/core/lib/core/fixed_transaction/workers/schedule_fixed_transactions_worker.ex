defmodule Core.FixedTransaction.Workers.ScheduleFixedTransactionsWorker do
  @moduledoc """
  Oban worker that runs daily and creates a `Transaction` for each
  `FixedTransaction` whose `day_of_month` matches today.

  A transaction is only created if one does not already exist for that
  `fixed_transaction_id` in the current month (idempotency safeguard).

  The transaction name is formatted as "name - month" (e.g. "Aluguel - março").
  """

  use Oban.Worker, queue: :default

  import Ecto.Query

  alias Core.Repo
  alias Core.Schemas.FixedTransaction
  alias Core.Schemas.Transaction
  alias Core.Transaction.Commands.CreateTransactionCommand
  alias Core.Transaction.Services.CreateTransactionService

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    today = Date.utc_today()

    queryable =
      from(ft in FixedTransaction, where: ft.day_of_month == ^today.day and ft.active == true)

    queryable
    |> Repo.all()
    |> Enum.each(&maybe_create_transaction(&1, today))

    :ok
  end

  defp maybe_create_transaction(ft, today) do
    unless transaction_exists_this_month?(ft.id, today) do
      command =
        CreateTransactionCommand.build!(%{
          user_id: ft.user_id,
          category_id: ft.category_id,
          fixed_transaction_id: ft.id,
          name: "#{ft.name} - #{Calendar.strftime(today, "%m/%Y")}",
          value_in_cents: ft.value_in_cents,
          date: Date.new!(today.year, today.month, ft.day_of_month),
          type: ft.type
        })

      CreateTransactionService.execute(command)
    end
  end

  defp transaction_exists_this_month?(ft_id, date) do
    start_date = Date.beginning_of_month(date)
    end_date = Date.end_of_month(date)

    Repo.exists?(
      from t in Transaction,
        where:
          t.fixed_transaction_id == ^ft_id and
            t.date >= ^start_date and
            t.date <= ^end_date
    )
  end
end
