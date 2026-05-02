defmodule Core.Repo.Migrations.CreateLlmUsageHistory do
  use Ecto.Migration

  def change do
    create table(:llm_usage_history, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      add :conversation_id,
          references(:conversations, type: :binary_id, on_delete: :delete_all),
          null: false

      add :message_id, references(:messages, type: :binary_id, on_delete: :delete_all),
        null: false

      add :model, :string, null: false
      add :input_tokens, :integer, null: false, default: 0
      add :cached_input_tokens, :integer, null: false, default: 0
      add :output_tokens, :integer, null: false, default: 0

      add :inserted_at, :utc_datetime_usec, null: false
    end

    create index(:llm_usage_history, [:user_id])
    create index(:llm_usage_history, [:conversation_id])
    create index(:llm_usage_history, [:message_id])
    create index(:llm_usage_history, [:user_id, :inserted_at])
    create index(:llm_usage_history, [:model])
  end
end
