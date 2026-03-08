defmodule Core.Repo.Migrations.AddDateToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :date, :date, null: false, default: fragment("CURRENT_DATE")
    end

    drop index(:transactions, [:user_id])
    create index(:transactions, [:user_id, :date])
  end
end
