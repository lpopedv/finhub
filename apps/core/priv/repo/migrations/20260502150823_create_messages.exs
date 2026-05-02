defmodule Core.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :conversation_id,
          references(:conversations, type: :binary_id, on_delete: :delete_all),
          null: false

      add :role, :string, null: false
      add :content, :text, null: false
      add :status, :string, null: false
      add :llm_model, :string
      add :input_tokens, :integer
      add :cached_input_tokens, :integer
      add :output_tokens, :integer

      add :inserted_at, :utc_datetime_usec, null: false
      add :updated_at, :utc_datetime_usec, null: false
    end

    create index(:messages, [:conversation_id])
    create index(:messages, [:conversation_id, :inserted_at])

    create constraint(:messages, :llm_model_required_for_assistant,
             check: "role != 'assistant' OR llm_model IS NOT NULL"
           )

    create constraint(:messages, :user_message_always_completed,
             check: "role != 'user' OR status = 'completed'"
           )
  end
end
