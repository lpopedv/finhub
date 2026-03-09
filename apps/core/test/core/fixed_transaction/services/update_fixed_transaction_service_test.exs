defmodule Core.FixedTransaction.Services.UpdateFixedTransactionServiceTest do
  use Core.DataCase, async: true

  alias Core.FixedTransaction.Services.UpdateFixedTransactionService

  describe "execute/2" do
    test "updates and returns the fixed transaction on success" do
      ft = insert(:fixed_transaction, name: "Aluguel", value_in_cents: 100_000, day_of_month: 5)

      assert {:ok, updated} =
               UpdateFixedTransactionService.execute(ft.id, %{
                 "name" => "Aluguel Novo",
                 "value_in_cents" => "120000",
                 "day_of_month" => "10"
               })

      assert updated.name == "Aluguel Novo"
      assert updated.value_in_cents == 120_000
      assert updated.day_of_month == 10
    end

    test "returns error for unknown id" do
      assert {:error, :not_found} =
               UpdateFixedTransactionService.execute(Uniq.UUID.uuid7(), %{"name" => "X"})
    end

    test "returns error changeset for invalid day_of_month" do
      ft = insert(:fixed_transaction)

      assert {:error, changeset} =
               UpdateFixedTransactionService.execute(ft.id, %{"day_of_month" => "0"})

      assert %{day_of_month: ["is invalid"]} = errors_on(changeset)
    end
  end
end
