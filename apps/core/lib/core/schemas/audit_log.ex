defmodule Core.Schemas.AuditLog do
  @moduledoc """
  Schema representing an immutable audit trail entry.

  Append-only and partitioned by month (RANGE on inserted_at). Each significant
  domain action (create, update, delete, restore) produces one record within
  the same database transaction as the action itself.

  action follows the format "resource.operation" — e.g. "ai_agent.create".
  resource_id stores the UUID of the affected record without a FK constraint,
  since the record may be soft-deleted or belong to any resource type.
  changes holds a list of field-level diffs: [%{field, old, new}].
  """

  use Core.Schema

  alias Core.Schemas.User

  @required_params [:actor_id, :action, :resource_type, :resource_id]
  @optional_params [:changes, :metadata]

  @type t :: %__MODULE__{
          id: Uniq.UUID.formatted(),
          actor_id: Uniq.UUID.formatted(),
          action: String.t(),
          resource_type: String.t(),
          resource_id: Ecto.UUID.t(),
          changes: [map()] | nil,
          metadata: map() | nil,
          inserted_at: DateTime.t()
        }

  schema "audit_logs" do
    field :action, :string
    field :resource_type, :string
    field :resource_id, :binary_id
    field :changes, {:array, :map}
    field :metadata, :map

    belongs_to :actor, User, foreign_key: :actor_id

    timestamps(updated_at: false)
  end

  @spec changeset(%__MODULE__{} | t(), map()) :: Ecto.Changeset.t()
  def changeset(schema \\ %__MODULE__{}, params),
    do:
      schema
      |> cast(params, @required_params ++ @optional_params)
      |> validate_required(@required_params)
      |> assoc_constraint(:actor)
end
