defmodule Core.FixedTransaction.Services.DeleteFixedTransactionServiceTest do
  use Core.DataCase, async: true

  alias Core.FixedTransaction.Services.DeleteFixedTransactionService
  alias Core.Repo
  alias Core.Schemas.FixedTransaction
  alias Core.Schemas.Transaction

  describe "execute/1" do
    test "deletes and returns the fixed transaction" do
      ft = insert(:fixed_transaction)

      assert {:ok, deleted} = DeleteFixedTransactionService.execute(ft.id)
      assert deleted.id == ft.id
      refute Repo.get(FixedTransaction, ft.id)
    end

    test "returns error for unknown id" do
      assert {:error, :not_found} = DeleteFixedTransactionService.execute(Uniq.UUID.uuid7())
    end

    test "nullifies fixed_transaction_id on associated transactions" do
      user = insert(:user)
      ft = insert(:fixed_transaction, user: user)

      transaction =
        insert(:transaction, user: user, fixed_transaction: ft)

      DeleteFixedTransactionService.execute(ft.id)

      updated = Repo.get(Transaction, transaction.id)
      assert is_nil(updated.fixed_transaction_id)
    end
  end
end
