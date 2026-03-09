defmodule Core.FixedTransaction.Services.ListFixedTransactionsServiceTest do
  use Core.DataCase, async: true

  alias Core.FixedTransaction.Services.ListFixedTransactionsService

  describe "execute/1" do
    test "returns only the user's fixed transactions" do
      user = insert(:user)
      other_user = insert(:user)

      insert(:fixed_transaction, user: user, name: "Aluguel")
      insert(:fixed_transaction, user: other_user, name: "Outro Aluguel")

      result = ListFixedTransactionsService.execute(user.id)

      assert length(result) == 1
      assert hd(result).name == "Aluguel"
    end

    test "returns empty list when user has no fixed transactions" do
      user = insert(:user)

      assert [] == ListFixedTransactionsService.execute(user.id)
    end

    test "orders by day_of_month ascending" do
      user = insert(:user)

      insert(:fixed_transaction, user: user, name: "Dia 15", day_of_month: 15)
      insert(:fixed_transaction, user: user, name: "Dia 1", day_of_month: 1)
      insert(:fixed_transaction, user: user, name: "Dia 28", day_of_month: 28)

      result = ListFixedTransactionsService.execute(user.id)
      days = Enum.map(result, & &1.day_of_month)

      assert days == [1, 15, 28]
    end
  end
end
