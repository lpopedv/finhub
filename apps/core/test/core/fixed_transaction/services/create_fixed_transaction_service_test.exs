defmodule Core.FixedTransaction.Services.CreateFixedTransactionServiceTest do
  use Core.DataCase, async: true

  alias Core.FixedTransaction.Commands.CreateFixedTransactionCommand
  alias Core.FixedTransaction.Services.CreateFixedTransactionService
  alias Core.Schemas.FixedTransaction

  setup do
    user = insert(:user)

    command =
      CreateFixedTransactionCommand.build!(%{
        user_id: user.id,
        name: "Aluguel",
        value_in_cents: 150_000,
        day_of_month: 5
      })

    %{command: command, user: user}
  end

  describe "execute/1" do
    test "creates and returns the fixed transaction on success", %{command: command} do
      assert {:ok, %FixedTransaction{} = ft} = CreateFixedTransactionService.execute(command)

      assert ft.id
      assert ft.user_id == command.user_id
      assert ft.name == command.name
      assert ft.value_in_cents == command.value_in_cents
      assert ft.day_of_month == command.day_of_month
    end

    test "persists the fixed transaction to the database", %{command: command} do
      {:ok, ft} = CreateFixedTransactionService.execute(command)

      assert Repo.get(FixedTransaction, ft.id)
    end

    test "creates fixed transaction with category", %{user: user} do
      category = insert(:category, user: user)

      command =
        CreateFixedTransactionCommand.build!(%{
          user_id: user.id,
          name: "Netflix",
          value_in_cents: 4_590,
          day_of_month: 15,
          category_id: category.id
        })

      assert {:ok, ft} = CreateFixedTransactionService.execute(command)
      assert ft.category_id == category.id
    end

    test "returns error for day_of_month below 1", %{user: user} do
      assert {:error, changeset} =
               CreateFixedTransactionCommand.build(%{
                 user_id: user.id,
                 name: "Inválido",
                 value_in_cents: 1000,
                 day_of_month: 0
               })

      assert %{day_of_month: ["is invalid"]} = errors_on(changeset)
    end

    test "returns error for day_of_month above 28", %{user: user} do
      assert {:error, changeset} =
               CreateFixedTransactionCommand.build(%{
                 user_id: user.id,
                 name: "Inválido",
                 value_in_cents: 1000,
                 day_of_month: 29
               })

      assert %{day_of_month: ["is invalid"]} = errors_on(changeset)
    end
  end
end
