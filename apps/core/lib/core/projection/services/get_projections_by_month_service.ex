defmodule Core.Projection.Services.GetProjectionsByMonthService do
  @moduledoc """
  Service for projecting financial totals grouped by month.

  Combines active fixed transactions (constant across all months) with
  variable transactions already entered for each month in the range.

  Returns a list of `%{month: Date.t(), projected_in_cents: integer()}` maps
  ordered by month ascending.
  """

  import Ecto.Query

  alias Core.Projection.Commands.GetProjectionsByMonthCommand
  alias Core.Repo
  alias Core.Schemas.FixedTransaction
  alias Core.Schemas.Transaction

  @spec execute(GetProjectionsByMonthCommand.t()) ::
          {:ok, [%{month: Date.t(), projected_in_cents: integer()}]}
  def execute(%GetProjectionsByMonthCommand{date_start: date_start, date_end: date_end} = command) do
    fixed_total = get_fixed_total(command)

    projections =
      command
      |> get_transaction_totals_by_month()
      |> fill_missing_months(date_start, date_end)
      |> Enum.map(fn {month, total} ->
        %{month: month, projected_in_cents: fixed_total + total}
      end)

    {:ok, projections}
  end

  defp get_fixed_total(%GetProjectionsByMonthCommand{user_id: user_id, type: type}) do
    queryable =
      from(ft in FixedTransaction,
        where: ft.user_id == ^user_id,
        where: ft.active == true,
        select: coalesce(sum(ft.value_in_cents), 0)
      )

    queryable
    |> maybe_filter_type(type)
    |> Repo.one()
  end

  defp get_transaction_totals_by_month(%GetProjectionsByMonthCommand{
         user_id: user_id,
         date_start: date_start,
         date_end: date_end,
         type: type
       }) do
    queryable =
      from(t in Transaction,
        where: t.user_id == ^user_id,
        where: is_nil(t.fixed_transaction_id),
        where: t.date >= ^date_start,
        where: t.date <= ^date_end,
        group_by: fragment("date_trunc('month', ?)", t.date),
        select: %{
          month: type(fragment("date_trunc('month', ?)", t.date), :date),
          total_in_cents: sum(t.value_in_cents)
        }
      )

    queryable
    |> maybe_filter_type(type)
    |> Repo.all()
    |> Map.new(fn %{month: month, total_in_cents: total} -> {month, total} end)
  end

  defp fill_missing_months(totals_by_month, date_start, date_end) do
    start = Date.beginning_of_month(date_start)
    stop = Date.beginning_of_month(date_end)

    start
    |> Stream.iterate(fn month -> Date.shift(month, month: 1) end)
    |> Stream.take_while(fn month -> Date.compare(month, stop) != :gt end)
    |> Map.new(fn month -> {month, Map.get(totals_by_month, month, 0)} end)
  end

  defp maybe_filter_type(queryable, nil), do: queryable
  defp maybe_filter_type(queryable, type), do: where(queryable, [t], t.type == ^type)
end
