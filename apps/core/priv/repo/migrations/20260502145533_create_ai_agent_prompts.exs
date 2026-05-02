defmodule Core.Repo.Migrations.CreateAiAgentPrompts do
  use Ecto.Migration

  def change do
    create table(:ai_agent_prompts, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :ai_agent_id, references(:ai_agents, type: :binary_id, on_delete: :delete_all),
        null: false

      add :content, :text, null: false
      add :version, :integer, null: false
      add :active, :boolean, default: false, null: false
      add :became_active_at, :utc_datetime_usec

      add :base_version_id,
          references(:ai_agent_prompts, type: :binary_id, on_delete: :nilify_all)

      add :inserted_at, :utc_datetime_usec, null: false
      add :updated_at, :utc_datetime_usec, null: false
    end

    create index(:ai_agent_prompts, [:ai_agent_id])
    create unique_index(:ai_agent_prompts, [:ai_agent_id, :version])

    create unique_index(:ai_agent_prompts, [:ai_agent_id],
             where: "active = true",
             name: :ai_agent_prompts_one_active_per_agent_index
           )

    create index(:ai_agent_prompts, [:base_version_id])
  end
end
