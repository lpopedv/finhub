defmodule Core.Auth.Commands.AuthenticateUserCommand do
  @moduledoc """
  Command for authenticating a user with email and password.

  ## Fields

  - `email` - Email address of the user (required)
  - `password` - Plain-text password to verify (required)
  """

  use Core.EmbeddedSchema

  alias Core.Schemas.Validators

  @required_params [:email, :password]

  @type t :: %__MODULE__{
          email: String.t(),
          password: String.t()
        }

  embedded_schema do
    field(:email, :string)
    field(:password, :string)
  end

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(params),
    do:
      %__MODULE__{}
      |> cast(params, @required_params)
      |> validate_required(@required_params)
      |> Validators.validate_email(:email)
end
