defmodule Core.Repo.Migrations.CreateAiAgents do
  use Ecto.Migration

  def change do
    create table(:ai_agents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, size: 255, null: false
      add :description, :string
      add :deleted, :boolean, default: false, null: false
      add :deleted_at, :utc_datetime_usec

      add :inserted_at, :utc_datetime_usec, null: false
      add :updated_at, :utc_datetime_usec, null: false
    end

    create index(:ai_agents, [:user_id])
    create index(:ai_agents, [:user_id, :deleted], where: "deleted = false")
  end
end
