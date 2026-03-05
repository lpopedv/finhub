defmodule Core.Category.Commands.CreateCategoryCommand do
  @moduledoc """
  Command for creating a new category.

  ## Fields

  - `user_id` - UUID of the owning user (required)
  - `name` - Category name, unique per user (required, max 100 characters)
  - `description` - Optional description
  """

  use Core.EmbeddedSchema

  @required_params [:user_id, :name]
  @optional_params [:description]

  @type t :: %__MODULE__{
          user_id: String.t(),
          name: String.t(),
          description: String.t() | nil
        }

  embedded_schema do
    field(:user_id, :string)
    field(:name, :string)
    field(:description, :string)
  end

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(params),
    do:
      %__MODULE__{}
      |> cast(params, @required_params ++ @optional_params)
      |> validate_required(@required_params)
      |> validate_length(:name, min: 1, max: 100)
end
