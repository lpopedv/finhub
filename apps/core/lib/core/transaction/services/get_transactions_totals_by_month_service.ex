defmodule Core.Transaction.Services.GetTransactionsTotalsByMonthService do
  @moduledoc """
  Service for summing transactions grouped by month within a date range.

  Returns a list of `%{month: Date.t(), total_in_cents: integer()}` maps
  ordered by month ascending. Optionally filters by transaction type.
  """

  import Ecto.Query

  alias Core.Repo
  alias Core.Schemas.Transaction
  alias Core.Transaction.Commands.GetTransactionsTotalsByMonthCommand

  @spec execute(GetTransactionsTotalsByMonthCommand.t()) ::
          {:ok, [%{month: Date.t(), total_in_cents: integer()}]}
  def execute(%GetTransactionsTotalsByMonthCommand{} = command) do
    queryable =
      from(t in Transaction,
        where: t.user_id == ^command.user_id,
        where: t.date >= ^command.date_start,
        where: t.date <= ^command.date_end,
        group_by: fragment("date_trunc('month', ?)", t.date),
        order_by: [asc: fragment("date_trunc('month', ?)", t.date)],
        select: %{
          month: type(fragment("date_trunc('month', ?)", t.date), :date),
          total_in_cents: sum(t.value_in_cents)
        }
      )

    result =
      queryable
      |> maybe_filter_type(command.type)
      |> Repo.all()

    {:ok, result}
  end

  defp maybe_filter_type(queryable, nil), do: queryable
  defp maybe_filter_type(queryable, type), do: where(queryable, [t], t.type == ^type)
end
