defmodule Core.Schemas.AiAgent do
  @moduledoc """
  Schema representing an AI agent persona.

  Agents belong to a user and carry a name and description that define their focus.
  Three default agents are created automatically on user signup (is_default: true).
  Deletion is soft — the record is kept with deleted: true and a deleted_at timestamp.
  """

  use Core.Schema

  alias Core.Schemas.User

  @required_params [:user_id, :name]
  @optional_params [:description]

  @type t :: %__MODULE__{
          id: Uniq.UUID.formatted(),
          user_id: Uniq.UUID.formatted(),
          name: String.t(),
          description: String.t() | nil,
          deleted: boolean(),
          deleted_at: DateTime.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t() | nil
        }

  schema "ai_agents" do
    field :name, :string
    field :description, :string
    field :deleted, :boolean, default: false
    field :deleted_at, :utc_datetime_usec

    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(%__MODULE__{} | t(), map()) :: Ecto.Changeset.t()
  def changeset(schema \\ %__MODULE__{}, params),
    do:
      schema
      |> cast(params, @required_params ++ @optional_params)
      |> validate_required(@required_params)
      |> validate_length(:name, max: 255)
      |> assoc_constraint(:user)
end
