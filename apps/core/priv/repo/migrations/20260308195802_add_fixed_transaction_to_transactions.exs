defmodule Core.Repo.Migrations.AddFixedTransactionToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :fixed_transaction_id,
          references(:fixed_transactions, type: :binary_id, on_delete: :nilify_all)

      remove :is_fixed
    end

    create index(:transactions, [:fixed_transaction_id])
  end
end
