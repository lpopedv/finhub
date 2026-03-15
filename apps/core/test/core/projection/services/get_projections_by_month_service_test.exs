defmodule Core.Projection.Services.GetProjectionsByMonthServiceTest do
  use Core.DataCase, async: true

  alias Core.Projection.Commands.GetProjectionsByMonthCommand
  alias Core.Projection.Services.GetProjectionsByMonthService

  setup do
    user = insert(:user)

    command =
      GetProjectionsByMonthCommand.build!(%{
        user_id: user.id,
        date_start: ~D[2026-01-01],
        date_end: ~D[2026-03-31]
      })

    %{user: user, command: command}
  end

  describe "execute/1" do
    test "returns all months in range with fixed total even without variable transactions", %{
      user: user,
      command: command
    } do
      insert(:fixed_transaction, user: user, value_in_cents: 2000, active: true)

      {:ok, projections} = GetProjectionsByMonthService.execute(command)

      assert length(projections) == 3
      assert Enum.all?(projections, &(&1.projected_in_cents == 2000))
      assert Enum.map(projections, & &1.month) == [~D[2026-01-01], ~D[2026-02-01], ~D[2026-03-01]]
    end

    test "returns months with zero when no fixed or variable transactions", %{command: command} do
      {:ok, projections} = GetProjectionsByMonthService.execute(command)

      assert length(projections) == 3
      assert Enum.all?(projections, &(&1.projected_in_cents == 0))
    end

    test "includes variable transactions already entered for a month", %{
      user: user,
      command: command
    } do
      insert(:fixed_transaction, user: user, value_in_cents: 1000, active: true)

      insert(:transaction,
        user: user,
        value_in_cents: 500,
        date: ~D[2026-02-15],
        fixed_transaction: nil
      )

      {:ok, [jan, feb, mar]} = GetProjectionsByMonthService.execute(command)

      assert jan.projected_in_cents == 1000
      assert feb.projected_in_cents == 1500
      assert mar.projected_in_cents == 1000
    end

    test "does not include transactions with fixed_transaction_id set", %{
      user: user,
      command: command
    } do
      insert(:fixed_transaction, user: user, value_in_cents: 1000, active: true)
      fixed = insert(:fixed_transaction, user: user, value_in_cents: 500, active: true)

      insert(:transaction,
        user: user,
        value_in_cents: 500,
        date: ~D[2026-01-10],
        fixed_transaction: fixed
      )

      {:ok, [jan | _rest]} = GetProjectionsByMonthService.execute(command)

      # fixed total = 1000 + 500 = 1500, but the transaction with fixed_transaction_id is excluded
      assert jan.projected_in_cents == 1500
    end

    test "filters by expense type", %{user: user} do
      insert(:fixed_transaction, user: user, value_in_cents: 3000, active: true, type: :expense)
      insert(:fixed_transaction, user: user, value_in_cents: 5000, active: true, type: :income)

      insert(:transaction,
        user: user,
        value_in_cents: 200,
        date: ~D[2026-01-10],
        type: :expense,
        fixed_transaction: nil
      )

      insert(:transaction,
        user: user,
        value_in_cents: 800,
        date: ~D[2026-01-20],
        type: :income,
        fixed_transaction: nil
      )

      command =
        GetProjectionsByMonthCommand.build!(%{
          user_id: user.id,
          date_start: ~D[2026-01-01],
          date_end: ~D[2026-01-31],
          type: :expense
        })

      {:ok, [jan]} = GetProjectionsByMonthService.execute(command)

      assert jan.projected_in_cents == 3200
    end

    test "filters by income type", %{user: user} do
      insert(:fixed_transaction, user: user, value_in_cents: 3000, active: true, type: :expense)
      insert(:fixed_transaction, user: user, value_in_cents: 5000, active: true, type: :income)

      insert(:transaction,
        user: user,
        value_in_cents: 200,
        date: ~D[2026-01-10],
        type: :expense,
        fixed_transaction: nil
      )

      insert(:transaction,
        user: user,
        value_in_cents: 800,
        date: ~D[2026-01-20],
        type: :income,
        fixed_transaction: nil
      )

      command =
        GetProjectionsByMonthCommand.build!(%{
          user_id: user.id,
          date_start: ~D[2026-01-01],
          date_end: ~D[2026-01-31],
          type: :income
        })

      {:ok, [jan]} = GetProjectionsByMonthService.execute(command)

      assert jan.projected_in_cents == 5800
    end

    test "does not count inactive fixed transactions", %{user: user, command: command} do
      insert(:fixed_transaction, user: user, value_in_cents: 2000, active: false)

      {:ok, projections} = GetProjectionsByMonthService.execute(command)

      assert Enum.all?(projections, &(&1.projected_in_cents == 0))
    end

    test "does not include data from other users", %{command: command} do
      other_user = insert(:user)
      insert(:fixed_transaction, user: other_user, value_in_cents: 9999, active: true)

      insert(:transaction,
        user: other_user,
        value_in_cents: 9999,
        date: ~D[2026-01-10],
        fixed_transaction: nil
      )

      {:ok, projections} = GetProjectionsByMonthService.execute(command)

      assert Enum.all?(projections, &(&1.projected_in_cents == 0))
    end
  end
end
