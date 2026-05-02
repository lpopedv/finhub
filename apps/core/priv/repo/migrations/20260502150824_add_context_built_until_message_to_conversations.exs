defmodule Core.Repo.Migrations.AddContextBuiltUntilMessageToConversations do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add :context_built_until_message_id,
          references(:messages, type: :binary_id, on_delete: :nilify_all)
    end
  end
end
