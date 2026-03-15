defmodule Core.Transaction.Services.ListTransactionsServiceTest do
  use Core.DataCase, async: true

  alias Core.Transaction.Commands.ListTransactionsCommand
  alias Core.Transaction.Services.ListTransactionsService

  setup do
    %{user: insert(:user)}
  end

  defp build_command(user_id, opts \\ []) do
    ListTransactionsCommand.build!(%{user_id: user_id, search: opts[:search]})
  end

  describe "execute/1" do
    test "returns empty list when user has no transactions", %{user: user} do
      assert [] = ListTransactionsService.execute(build_command(user.id))
    end

    test "returns only transactions belonging to the user", %{user: user} do
      transaction = insert(:transaction, user: user)
      insert(:transaction)

      assert [result] = ListTransactionsService.execute(build_command(user.id))
      assert result.id == transaction.id
    end

    test "returns transactions ordered by insertion date, most recent first", %{user: user} do
      first = insert(:transaction, user: user)
      second = insert(:transaction, user: user)

      assert [most_recent, oldest] = ListTransactionsService.execute(build_command(user.id))
      assert most_recent.id == second.id
      assert oldest.id == first.id
    end

    test "filters by transaction name case-insensitively", %{user: user} do
      insert(:transaction, user: user, name: "Aluguel")
      insert(:transaction, user: user, name: "Internet")

      assert [result] = ListTransactionsService.execute(build_command(user.id, search: "alug"))
      assert result.name == "Aluguel"
    end

    test "filters by category name case-insensitively", %{user: user} do
      moradia = insert(:category, user: user, name: "Moradia")
      insert(:transaction, user: user, name: "Aluguel", category: moradia)
      insert(:transaction, user: user, name: "Internet", category: nil)

      assert [result] = ListTransactionsService.execute(build_command(user.id, search: "mora"))
      assert result.name == "Aluguel"
    end

    test "preloads category", %{user: user} do
      category = insert(:category, user: user)
      insert(:transaction, user: user, category: category)

      assert [result] = ListTransactionsService.execute(build_command(user.id))
      assert result.category.id == category.id
    end
  end
end
