defmodule Core.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :ai_agent_id, references(:ai_agents, type: :binary_id, on_delete: :nilify_all)
      add :title, :string
      add :active, :boolean, default: true, null: false
      add :last_message_at, :utc_datetime_usec

      add :inserted_at, :utc_datetime_usec, null: false
      add :updated_at, :utc_datetime_usec, null: false
    end

    create index(:conversations, [:user_id])
    create index(:conversations, [:ai_agent_id])
    create index(:conversations, [:user_id, :last_message_at])
    create index(:conversations, [:user_id, :active], where: "active = true")
  end
end
