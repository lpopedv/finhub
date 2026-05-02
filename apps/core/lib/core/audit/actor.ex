defmodule Core.Audit.Actor do
  @moduledoc """
  Embedded schema representing the actor who triggered an auditable action.

  actor_id is the UUID of the user performing the action.
  actor_type is always :user for now — extensible for service accounts later.
  """

  use Core.EmbeddedSchema

  @required_params [:actor_id]
  @optional_params [:actor_type]

  @type actor_type :: :user
  @type t :: %__MODULE__{
          actor_id: Uniq.UUID.formatted(),
          actor_type: actor_type()
        }

  embedded_schema do
    field :actor_id, Uniq.UUID
    field :actor_type, Ecto.Enum, values: [:user], default: :user
  end

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(params),
    do:
      %__MODULE__{}
      |> cast(params, @required_params ++ @optional_params)
      |> validate_required(@required_params)
end
