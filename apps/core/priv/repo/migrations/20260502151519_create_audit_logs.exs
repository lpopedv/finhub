defmodule Core.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  # Ecto's DSL does not support PARTITION BY — raw SQL is required.
  # The PK must include the partition key, so we use (id, inserted_at).
  # Ecto generates the UUID before insert and uses RETURNING id, which
  # works correctly even with a composite DB-level primary key.
  def up do
    execute """
    CREATE TABLE audit_logs (
      id uuid NOT NULL,
      actor_id uuid NOT NULL REFERENCES users(id),
      action varchar NOT NULL,
      resource_type varchar NOT NULL,
      resource_id uuid NOT NULL,
      changes jsonb,
      metadata jsonb,
      inserted_at timestamptz NOT NULL,
      PRIMARY KEY (id, inserted_at)
    ) PARTITION BY RANGE (inserted_at)
    """

    execute "CREATE INDEX ON audit_logs (actor_id)"
    execute "CREATE INDEX ON audit_logs (resource_type, resource_id)"
    execute "CREATE INDEX ON audit_logs (action)"
    execute "CREATE INDEX ON audit_logs (inserted_at)"

    execute """
    CREATE TABLE audit_logs_2026_05 PARTITION OF audit_logs
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01')
    """
  end

  def down do
    execute "DROP TABLE IF EXISTS audit_logs CASCADE"
  end
end
