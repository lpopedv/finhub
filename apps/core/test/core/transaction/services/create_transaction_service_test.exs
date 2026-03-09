defmodule Core.Transaction.Services.CreateTransactionServiceTest do
  use Core.DataCase, async: true

  alias Core.Schemas.Transaction
  alias Core.Transaction.Commands.CreateTransactionCommand
  alias Core.Transaction.Services.CreateTransactionService

  setup do
    user = insert(:user)

    command =
      CreateTransactionCommand.build!(%{
        user_id: user.id,
        name: "Groceries",
        value_in_cents: 5000,
        date: ~D[2026-03-08],
        type: :expense
      })

    %{command: command, user: user}
  end

  describe "execute/1" do
    test "creates and returns the transaction on success", %{command: command} do
      assert {:ok, %Transaction{} = transaction} = CreateTransactionService.execute(command)

      assert transaction.id
      assert transaction.user_id == command.user_id
      assert transaction.name == command.name
      assert transaction.value_in_cents == command.value_in_cents
    end

    test "persists the transaction to the database", %{command: command} do
      {:ok, transaction} = CreateTransactionService.execute(command)

      assert Repo.get(Transaction, transaction.id)
    end

    test "creates transaction with category", %{user: user} do
      category = insert(:category, user: user)

      command =
        CreateTransactionCommand.build!(%{
          user_id: user.id,
          name: "Dinner",
          value_in_cents: 8000,
          category_id: category.id,
          date: ~D[2026-03-08],
          type: :expense
        })

      assert {:ok, transaction} = CreateTransactionService.execute(command)
      assert transaction.category_id == category.id
    end

    test "creates transaction linked to a fixed transaction", %{user: user} do
      fixed = insert(:fixed_transaction, user: user)

      command =
        CreateTransactionCommand.build!(%{
          user_id: user.id,
          name: "Aluguel",
          value_in_cents: 150_000,
          fixed_transaction_id: fixed.id,
          date: ~D[2026-03-08],
          type: :expense
        })

      assert {:ok, transaction} = CreateTransactionService.execute(command)
      assert transaction.fixed_transaction_id == fixed.id
    end
  end
end
