defmodule Core.Transaction.Services.GetTransactionsTotalsByMonthServiceTest do
  use Core.DataCase, async: true

  alias Core.Transaction.Commands.GetTransactionsTotalsByMonthCommand
  alias Core.Transaction.Services.GetTransactionsTotalsByMonthService

  setup do
    user = insert(:user)

    command =
      GetTransactionsTotalsByMonthCommand.build!(%{
        user_id: user.id,
        date_start: ~D[2025-01-01],
        date_end: ~D[2025-12-31]
      })

    %{user: user, command: command}
  end

  describe "execute/1" do
    test "returns empty list when no transactions in range", %{command: command} do
      assert {:ok, []} = GetTransactionsTotalsByMonthService.execute(command)
    end

    test "sums correctly for a single month", %{user: user, command: command} do
      insert(:transaction, user: user, date: ~D[2025-03-10], value_in_cents: 1000)
      insert(:transaction, user: user, date: ~D[2025-03-25], value_in_cents: 500)

      assert {:ok, [result]} = GetTransactionsTotalsByMonthService.execute(command)
      assert result.month == ~D[2025-03-01]
      assert result.total_in_cents == 1500
    end

    test "groups correctly across multiple months", %{user: user, command: command} do
      insert(:transaction, user: user, date: ~D[2025-01-15], value_in_cents: 200)
      insert(:transaction, user: user, date: ~D[2025-02-10], value_in_cents: 300)
      insert(:transaction, user: user, date: ~D[2025-03-05], value_in_cents: 400)

      assert {:ok, [jan, feb, mar]} = GetTransactionsTotalsByMonthService.execute(command)
      assert jan.month == ~D[2025-01-01]
      assert jan.total_in_cents == 200
      assert feb.month == ~D[2025-02-01]
      assert feb.total_in_cents == 300
      assert mar.month == ~D[2025-03-01]
      assert mar.total_in_cents == 400
    end

    test "filters by expense type", %{user: user} do
      insert(:transaction, user: user, date: ~D[2025-06-01], value_in_cents: 1000, type: :expense)
      insert(:transaction, user: user, date: ~D[2025-06-15], value_in_cents: 2000, type: :income)

      command =
        GetTransactionsTotalsByMonthCommand.build!(%{
          user_id: user.id,
          date_start: ~D[2025-01-01],
          date_end: ~D[2025-12-31],
          type: :expense
        })

      assert {:ok, [result]} = GetTransactionsTotalsByMonthService.execute(command)
      assert result.total_in_cents == 1000
    end

    test "filters by income type", %{user: user} do
      insert(:transaction, user: user, date: ~D[2025-06-01], value_in_cents: 1000, type: :expense)
      insert(:transaction, user: user, date: ~D[2025-06-15], value_in_cents: 2000, type: :income)

      command =
        GetTransactionsTotalsByMonthCommand.build!(%{
          user_id: user.id,
          date_start: ~D[2025-01-01],
          date_end: ~D[2025-12-31],
          type: :income
        })

      assert {:ok, [result]} = GetTransactionsTotalsByMonthService.execute(command)
      assert result.total_in_cents == 2000
    end

    test "excludes transactions outside the date range", %{user: user, command: command} do
      insert(:transaction, user: user, date: ~D[2024-12-31], value_in_cents: 999)
      insert(:transaction, user: user, date: ~D[2025-06-01], value_in_cents: 500)
      insert(:transaction, user: user, date: ~D[2026-01-01], value_in_cents: 999)

      assert {:ok, [result]} = GetTransactionsTotalsByMonthService.execute(command)
      assert result.month == ~D[2025-06-01]
      assert result.total_in_cents == 500
    end

    test "orders results by month ascending", %{user: user, command: command} do
      insert(:transaction, user: user, date: ~D[2025-12-01], value_in_cents: 100)
      insert(:transaction, user: user, date: ~D[2025-01-01], value_in_cents: 100)
      insert(:transaction, user: user, date: ~D[2025-06-01], value_in_cents: 100)

      assert {:ok, results} = GetTransactionsTotalsByMonthService.execute(command)
      months = Enum.map(results, & &1.month)
      assert months == Enum.sort(months, Date)
    end

    test "does not include transactions from other users", %{command: command} do
      insert(:transaction, date: ~D[2025-06-01], value_in_cents: 5000)

      assert {:ok, []} = GetTransactionsTotalsByMonthService.execute(command)
    end
  end
end
