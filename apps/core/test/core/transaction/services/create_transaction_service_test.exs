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
        date: ~D[2026-03-08]
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
      assert transaction.is_fixed == false
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
          date: ~D[2026-03-08]
        })

      assert {:ok, transaction} = CreateTransactionService.execute(command)
      assert transaction.category_id == category.id
    end

    test "creates transaction with is_fixed set to true", %{user: user} do
      command =
        CreateTransactionCommand.build!(%{
          user_id: user.id,
          name: "Rent",
          value_in_cents: 150_000,
          is_fixed: true,
          date: ~D[2026-03-08]
        })

      assert {:ok, transaction} = CreateTransactionService.execute(command)
      assert transaction.is_fixed == true
    end
  end
end
