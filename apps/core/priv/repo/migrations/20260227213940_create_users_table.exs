defmodule Core.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :full_name, :string, size: 150, null: false
      add :email, :string, size: 150, null: false
      add :password_hash, :string, size: 255, null: false

      add :inserted_at, :utc_datetime_usec, null: false
      add :updated_at, :utc_datetime_usec, null: false
    end

    create unique_index(:users, :email)
  end
end
