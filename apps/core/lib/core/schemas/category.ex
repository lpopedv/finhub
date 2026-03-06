defmodule Core.Schemas.Category do
  @moduledoc """
  Schema representing a user-defined category.

  Categories are scoped to a user and have a unique name per user.
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
          inserted_at: DateTime.t(),
          updated_at: DateTime.t() | nil
        }

  schema "categories" do
    field :name, :string
    field :description, :string

    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(%__MODULE__{} | t(), map()) :: Ecto.Changeset.t()
  def changeset(schema \\ %__MODULE__{}, params),
    do:
      schema
      |> cast(params, @required_params ++ @optional_params)
      |> validate_required(@required_params)
      |> validate_length(:name, max: 100)
      |> unique_constraint(:name, name: :categories_user_id_name_index)
      |> assoc_constraint(:user)
end
