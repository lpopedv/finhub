defmodule Core.User.Commands.CreateUserCommand do
  @moduledoc """
  Command for creating a new user.

  ## Fields

  - `full_name` - Full name of the user (required)
  - `email` - Email address of the user (required)
  - `password` - Password for the user (required, min 8 characters)
  """

  use Core.EmbeddedSchema

  alias Core.Schemas.Validators

  @required_params [:full_name, :email, :password]

  @type t :: %__MODULE__{
          full_name: String.t(),
          email: String.t(),
          password: String.t()
        }

  embedded_schema do
    field(:full_name, :string)
    field(:email, :string)
    field(:password, :string)
  end

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(params),
    do:
      %__MODULE__{}
      |> cast(params, @required_params)
      |> validate_required(@required_params)
      |> validate_length(:full_name, min: 1, max: 150)
      |> validate_length(:email, min: 1, max: 150)
      |> validate_length(:password, min: 8)
      |> Validators.validate_email(:email)
end
