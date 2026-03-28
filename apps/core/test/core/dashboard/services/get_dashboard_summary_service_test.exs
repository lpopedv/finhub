defmodule Core.Dashboard.Services.GetDashboardSummaryServiceTest do
  use Core.DataCase, async: true

  alias Core.Dashboard.Services.GetDashboardSummaryService

  setup do
    %{user: insert(:user)}
  end

  describe "execute/1" do
    test "returns zeros when user has no data", %{user: user} do
      assert %{fixed_expenses_total: 0, next_month_expenses_total: 0} =
               GetDashboardSummaryService.execute(user.id)
    end

    # fixed_expenses_total

    test "sums active fixed expenses", %{user: user} do
      insert(:fixed_transaction, user: user, value_in_cents: 50_000, active: true, type: :expense)
      insert(:fixed_transaction, user: user, value_in_cents: 30_000, active: true, type: :expense)

      assert %{fixed_expenses_total: 80_000} = GetDashboardSummaryService.execute(user.id)
    end

    test "excludes inactive fixed transactions from fixed_expenses_total", %{user: user} do
      insert(:fixed_transaction, user: user, value_in_cents: 50_000, active: true, type: :expense)

      insert(:fixed_transaction,
        user: user,
        value_in_cents: 20_000,
        active: false,
        type: :expense
      )

      assert %{fixed_expenses_total: 50_000} = GetDashboardSummaryService.execute(user.id)
    end

    test "excludes income fixed transactions from fixed_expenses_total", %{user: user} do
      insert(:fixed_transaction, user: user, value_in_cents: 50_000, active: true, type: :expense)
      insert(:fixed_transaction, user: user, value_in_cents: 300_000, active: true, type: :income)

      assert %{fixed_expenses_total: 50_000} = GetDashboardSummaryService.execute(user.id)
    end

    test "does not include another user's fixed transactions", %{user: user} do
      other_user = insert(:user)

      insert(:fixed_transaction, user: user, value_in_cents: 10_000, active: true, type: :expense)

      insert(:fixed_transaction,
        user: other_user,
        value_in_cents: 99_000,
        active: true,
        type: :expense
      )

      assert %{fixed_expenses_total: 10_000} = GetDashboardSummaryService.execute(user.id)
    end

    # next_month_projected_expenses

    test "next_month_projected_expenses equals fixed_expenses_total when no variable transactions exist",
         %{user: user} do
      insert(:fixed_transaction, user: user, value_in_cents: 50_000, active: true, type: :expense)

      result = GetDashboardSummaryService.execute(user.id)

      assert result.next_month_expenses_total == result.fixed_expenses_total
    end

    test "adds variable expense transactions for next month to the projection", %{user: user} do
      next_month = Date.shift(Date.utc_today(), month: 1)

      insert(:fixed_transaction, user: user, value_in_cents: 50_000, active: true, type: :expense)
      insert(:transaction, user: user, value_in_cents: 15_000, type: :expense, date: next_month)

      assert %{next_month_expenses_total: 65_000} =
               GetDashboardSummaryService.execute(user.id)
    end

    test "excludes income transactions for next month from projection", %{user: user} do
      next_month = Date.shift(Date.utc_today(), month: 1)

      insert(:fixed_transaction, user: user, value_in_cents: 50_000, active: true, type: :expense)
      insert(:transaction, user: user, value_in_cents: 300_000, type: :income, date: next_month)

      assert %{next_month_expenses_total: 50_000} =
               GetDashboardSummaryService.execute(user.id)
    end

    test "excludes transactions from other months from projection", %{user: user} do
      insert(:fixed_transaction, user: user, value_in_cents: 50_000, active: true, type: :expense)

      insert(:transaction,
        user: user,
        value_in_cents: 20_000,
        type: :expense,
        date: Date.utc_today()
      )

      assert %{next_month_expenses_total: 50_000} =
               GetDashboardSummaryService.execute(user.id)
    end

    test "excludes fixed-transaction-linked entries for next month (already counted in fixed_expenses_total)",
         %{user: user} do
      next_month = Date.shift(Date.utc_today(), month: 1)

      fixed =
        insert(:fixed_transaction,
          user: user,
          value_in_cents: 50_000,
          active: true,
          type: :expense
        )

      insert(:transaction,
        user: user,
        fixed_transaction: fixed,
        value_in_cents: 50_000,
        type: :expense,
        date: next_month
      )

      result = GetDashboardSummaryService.execute(user.id)

      assert result.next_month_expenses_total == result.fixed_expenses_total
    end

    test "does not include another user's variable transactions in projection", %{user: user} do
      other_user = insert(:user)
      next_month = Date.shift(Date.utc_today(), month: 1)

      insert(:fixed_transaction, user: user, value_in_cents: 10_000, active: true, type: :expense)

      insert(:transaction,
        user: other_user,
        value_in_cents: 99_000,
        type: :expense,
        date: next_month
      )

      assert %{next_month_expenses_total: 10_000} =
               GetDashboardSummaryService.execute(user.id)
    end
  end
end
