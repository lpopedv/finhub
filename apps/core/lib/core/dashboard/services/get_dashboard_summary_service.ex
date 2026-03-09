defmodule Core.Dashboard.Services.GetDashboardSummaryService do
  @moduledoc """
  Returns a summary of financial data for the dashboard.

  - `fixed_expenses_total`: sum of all active fixed expense transactions (monthly commitment).
  - `next_month_projected_expenses`: fixed expenses + any variable expenses already entered for next month.
  """

  import Ecto.Query

  alias Core.Repo
  alias Core.Schemas.FixedTransaction
  alias Core.Schemas.Transaction

  @type summary :: %{
          fixed_expenses_total: non_neg_integer(),
          next_month_projected_expenses: non_neg_integer()
        }

  @spec execute(String.t()) :: summary()
  def execute(user_id) do
    today = Date.utc_today()
    next_month = Date.shift(today, month: 1)
    next_month_start = Date.beginning_of_month(next_month)
    next_month_end = Date.end_of_month(next_month)

    fixed_total_queryable =
      from(ft in FixedTransaction,
        where: ft.user_id == ^user_id and ft.active == true and ft.type == :expense,
        select: coalesce(sum(ft.value_in_cents), 0)
      )

    fixed_total = Repo.one(fixed_total_queryable)

    next_month_variable_queryable =
      from(t in Transaction,
        where:
          t.user_id == ^user_id and
            t.type == :expense and
            t.date >= ^next_month_start and
            t.date <= ^next_month_end and
            is_nil(t.fixed_transaction_id),
        select: coalesce(sum(t.value_in_cents), 0)
      )

    next_month_variable = Repo.one(next_month_variable_queryable)

    %{
      fixed_expenses_total: fixed_total,
      next_month_projected_expenses: fixed_total + next_month_variable
    }
  end
end
