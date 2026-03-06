defmodule Core.Repo.Migrations.CreateTransactionsTable do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :category_id, references(:categories, type: :binary_id, on_delete: :nilify_all)
      add :name, :string, size: 255, null: false
      add :value_in_cents, :integer, null: false
      add :is_fixed, :boolean, null: false, default: false

      add :inserted_at, :utc_datetime_usec, null: false
      add :updated_at, :utc_datetime_usec, null: false
    end

    create index(:transactions, :user_id)
    create index(:transactions, :category_id)
  end
end
