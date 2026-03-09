defmodule Core.FixedTransaction.Workers.ScheduleFixedTransactionsWorkerTest do
  use Core.DataCase, async: true
  use Oban.Testing, repo: Core.Repo

  alias Core.FixedTransaction.Workers.ScheduleFixedTransactionsWorker
  alias Core.Schemas.Transaction

  setup do
    %{today: Date.utc_today()}
  end

  describe "perform/1" do
    test "creates a transaction for each fixed transaction matching today", %{today: today} do
      user = insert(:user)
      ft = insert(:fixed_transaction, user: user, day_of_month: today.day)

      assert :ok = perform_job(ScheduleFixedTransactionsWorker, %{})

      transaction = Repo.get_by!(Transaction, fixed_transaction_id: ft.id)
      assert transaction.user_id == ft.user_id
      assert transaction.value_in_cents == ft.value_in_cents
      assert transaction.date == Date.new!(today.year, today.month, today.day)
    end

    test "formats the transaction name with the current month", %{today: today} do
      user = insert(:user)
      ft = insert(:fixed_transaction, user: user, day_of_month: today.day, name: "Aluguel")

      assert :ok = perform_job(ScheduleFixedTransactionsWorker, %{})

      transaction = Repo.get_by!(Transaction, fixed_transaction_id: ft.id)
      assert transaction.name == "Aluguel - #{Calendar.strftime(today, "%m/%Y")}"
    end

    test "skips fixed transactions for other days", %{today: today} do
      other_day = if today.day == 1, do: 2, else: 1
      insert(:fixed_transaction, day_of_month: other_day)

      assert :ok = perform_job(ScheduleFixedTransactionsWorker, %{})

      assert Repo.aggregate(Transaction, :count) == 0
    end

    test "does not create duplicate if transaction already exists this month", %{today: today} do
      user = insert(:user)
      ft = insert(:fixed_transaction, user: user, day_of_month: today.day)
      insert(:transaction, user: user, fixed_transaction_id: ft.id, date: today)

      assert :ok = perform_job(ScheduleFixedTransactionsWorker, %{})

      count =
        Repo.aggregate(
          from(t in Transaction, where: t.fixed_transaction_id == ^ft.id),
          :count
        )

      assert count == 1
    end

    test "creates transactions for multiple fixed transactions on same day", %{today: today} do
      user = insert(:user)
      ft1 = insert(:fixed_transaction, user: user, day_of_month: today.day)
      ft2 = insert(:fixed_transaction, user: user, day_of_month: today.day)

      assert :ok = perform_job(ScheduleFixedTransactionsWorker, %{})

      assert Repo.get_by!(Transaction, fixed_transaction_id: ft1.id)
      assert Repo.get_by!(Transaction, fixed_transaction_id: ft2.id)
    end

    test "propagates category to the created transaction", %{today: today} do
      user = insert(:user)
      category = insert(:category, user: user)
      ft = insert(:fixed_transaction, user: user, category: category, day_of_month: today.day)

      assert :ok = perform_job(ScheduleFixedTransactionsWorker, %{})

      transaction = Repo.get_by!(Transaction, fixed_transaction_id: ft.id)
      assert transaction.category_id == category.id
    end
  end
end
