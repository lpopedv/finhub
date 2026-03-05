defmodule Core.Transaction.Services.ListTransactionsServiceTest do
  use Core.DataCase, async: true

  alias Core.Transaction.Services.ListTransactionsService

  setup do
    %{user: insert(:user)}
  end

  describe "execute/1" do
    test "returns empty list when user has no transactions", %{user: user} do
      assert [] = ListTransactionsService.execute(user.id)
    end

    test "returns only transactions belonging to the user", %{user: user} do
      transaction = insert(:transaction, user: user)
      insert(:transaction)

      assert [result] = ListTransactionsService.execute(user.id)
      assert result.id == transaction.id
    end

    test "returns transactions ordered by insertion date, most recent first", %{user: user} do
      first = insert(:transaction, user: user)
      second = insert(:transaction, user: user)

      assert [most_recent, oldest] = ListTransactionsService.execute(user.id)
      assert most_recent.id == second.id
      assert oldest.id == first.id
    end
  end
end
