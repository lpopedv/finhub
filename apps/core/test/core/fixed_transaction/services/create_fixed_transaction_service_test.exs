defmodule Core.FixedTransaction.Services.CreateFixedTransactionServiceTest do
  use Core.DataCase, async: true

  alias Core.FixedTransaction.Commands.CreateFixedTransactionCommand
  alias Core.FixedTransaction.Services.CreateFixedTransactionService
  alias Core.Schemas.FixedTransaction
  alias Core.Schemas.Transaction

  setup do
    user = insert(:user)

    command =
      CreateFixedTransactionCommand.build!(%{
        user_id: user.id,
        name: "Aluguel",
        value_in_cents: 150_000,
        day_of_month: 5,
        type: :expense
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

    test "also creates a transaction for the current month", %{command: command} do
      today = Date.utc_today()

      {:ok, ft} = CreateFixedTransactionService.execute(command)

      transaction = Repo.get_by!(Transaction, fixed_transaction_id: ft.id)
      assert transaction.user_id == ft.user_id
      assert transaction.value_in_cents == ft.value_in_cents
      assert transaction.fixed_transaction_id == ft.id
      assert transaction.date == Date.new!(today.year, today.month, ft.day_of_month)
      assert transaction.name == "#{ft.name} - #{Calendar.strftime(today, "%m/%Y")}"
    end

    test "propagates category to the created transaction", %{user: user} do
      category = insert(:category, user: user)

      command =
        CreateFixedTransactionCommand.build!(%{
          user_id: user.id,
          name: "Netflix",
          value_in_cents: 4_590,
          day_of_month: 15,
          category_id: category.id,
          type: :expense
        })

      {:ok, ft} = CreateFixedTransactionService.execute(command)

      assert ft.category_id == category.id

      transaction = Repo.get_by!(Transaction, fixed_transaction_id: ft.id)
      assert transaction.category_id == category.id
    end

    test "rolls back both inserts if fixed transaction fails" do
      command =
        CreateFixedTransactionCommand.build!(%{
          user_id: Ecto.UUID.generate(),
          name: "Inválido",
          value_in_cents: 1000,
          day_of_month: 5,
          type: :expense
        })

      assert {:error, _changeset} = CreateFixedTransactionService.execute(command)
      assert Repo.aggregate(FixedTransaction, :count) == 0
      assert Repo.aggregate(Transaction, :count) == 0
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
