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
  def execute(%GetProjectionsByMonthCommand{} = command) do
    fixed_total = fetch_fixed_total(command)
    variable_by_month = fetch_variable_by_month(command)

    projections =
      build_projections(command.date_start, command.date_end, fixed_total, variable_by_month)

    {:ok, projections}
  end

  defp fetch_fixed_total(command) do
    query =
      from(ft in FixedTransaction,
        where: ft.user_id == ^command.user_id,
        where: ft.active == true,
        select: coalesce(sum(ft.value_in_cents), 0)
      )

    query
    |> maybe_filter_type(command.type)
    |> Repo.one()
  end

  defp fetch_variable_by_month(command) do
    query =
      from(t in Transaction,
        where: t.user_id == ^command.user_id,
        where: is_nil(t.fixed_transaction_id),
        where: t.date >= ^command.date_start,
        where: t.date <= ^command.date_end,
        group_by: fragment("date_trunc('month', ?)", t.date),
        select: %{
          month: type(fragment("date_trunc('month', ?)", t.date), :date),
          total_in_cents: sum(t.value_in_cents)
        }
      )

    query
    |> maybe_filter_type(command.type)
    |> Repo.all()
    |> Map.new(fn %{month: month, total_in_cents: total} -> {month, total} end)
  end

  defp build_projections(date_start, date_end, fixed_total, variable_by_month),
    do:
      date_start
      |> Date.beginning_of_month()
      |> months_stream()
      |> Stream.take_while(&before_or_on_end_month?(&1, date_end))
      |> Enum.map(&project_month(&1, fixed_total, variable_by_month))

  defp months_stream(start_month),
    do: Stream.iterate(start_month, fn month -> Date.shift(month, month: 1) end)

  defp before_or_on_end_month?(month, date_end),
    do: Date.compare(month, Date.beginning_of_month(date_end)) != :gt

  defp project_month(month, fixed_total, variable_by_month) do
    variable_total = Map.get(variable_by_month, month, 0)
    %{month: month, projected_in_cents: fixed_total + variable_total}
  end

  defp maybe_filter_type(queryable, nil), do: queryable
  defp maybe_filter_type(queryable, type), do: where(queryable, [t], t.type == ^type)
end
