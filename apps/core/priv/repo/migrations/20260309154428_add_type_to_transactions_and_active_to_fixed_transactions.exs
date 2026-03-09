defmodule Core.Repo.Migrations.AddTypeToTransactionsAndActiveToFixedTransactions do
  use Ecto.Migration

  def change do
    alter table(:fixed_transactions) do
      add :type, :string, null: false, default: "expense"
      add :active, :boolean, null: false, default: true
    end

    alter table(:transactions) do
      add :type, :string, null: false, default: "expense"
    end
  end
end
