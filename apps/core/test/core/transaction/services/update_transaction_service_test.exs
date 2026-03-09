defmodule Core.Transaction.Services.UpdateTransactionServiceTest do
  use Core.DataCase, async: true

  alias Core.Transaction.Services.UpdateTransactionService

  setup do
    %{transaction: insert(:transaction)}
  end

  describe "execute/2" do
    test "updates name", %{transaction: transaction} do
      assert {:ok, updated} = UpdateTransactionService.execute(transaction.id, %{name: "Rent"})
      assert updated.name == "Rent"
    end

    test "updates value_in_cents", %{transaction: transaction} do
      assert {:ok, updated} =
               UpdateTransactionService.execute(transaction.id, %{value_in_cents: 9999})

      assert updated.value_in_cents == 9999
    end

    test "updates category_id", %{transaction: transaction} do
      category = insert(:category, user: transaction.user)

      assert {:ok, updated} =
               UpdateTransactionService.execute(transaction.id, %{category_id: category.id})

      assert updated.category_id == category.id
    end

    test "returns error when transaction is not found" do
      assert {:error, :not_found} =
               UpdateTransactionService.execute(Uniq.UUID.uuid7(), %{name: "Ghost"})
    end

    test "returns error when value_in_cents is invalid", %{transaction: transaction} do
      assert {:error, changeset} =
               UpdateTransactionService.execute(transaction.id, %{value_in_cents: 0})

      assert "must be greater than 0" in errors_on(changeset)[:value_in_cents]
    end
  end
end
