defmodule Core.Repo.Migrations.CreateFixedTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:fixed_transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :category_id, references(:categories, type: :binary_id, on_delete: :nilify_all)
      add :name, :string, size: 255, null: false
      add :value_in_cents, :integer, null: false
      add :day_of_month, :integer, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:fixed_transactions, [:user_id])
    create index(:fixed_transactions, [:category_id])
  end
end
