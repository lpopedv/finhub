defmodule Core.Transaction.Services.DeleteTransactionServiceTest do
  use Core.DataCase, async: true

  alias Core.Schemas.Transaction
  alias Core.Transaction.Services.DeleteTransactionService

  setup do
    %{transaction: insert(:transaction)}
  end

  describe "execute/1" do
    test "deletes the transaction and returns it", %{transaction: transaction} do
      assert {:ok, deleted} = DeleteTransactionService.execute(transaction.id)
      assert deleted.id == transaction.id
    end

    test "removes the transaction from the database", %{transaction: transaction} do
      DeleteTransactionService.execute(transaction.id)

      refute Repo.get(Transaction, transaction.id)
    end

    test "returns error when transaction is not found" do
      assert {:error, :not_found} = DeleteTransactionService.execute(Uniq.UUID.uuid7())
    end
  end
end
