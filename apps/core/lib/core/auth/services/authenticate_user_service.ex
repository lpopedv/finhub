defmodule Core.Auth.Services.AuthenticateUserService do
  @moduledoc """
  Service for authenticating a user by email and password.

  Returns `{:ok, user}` on success, or `{:error, :invalid_credentials}` when
  the email is not found or the password does not match.
  """

  alias Core.Auth.Commands.AuthenticateUserCommand
  alias Core.Repo
  alias Core.Schemas.User

  @spec execute(AuthenticateUserCommand.t()) :: {:ok, User.t()} | {:error, :invalid_credentials}
  def execute(%AuthenticateUserCommand{email: email, password: password}) do
    case Repo.get_by(User, email: email) do
      nil ->
        Argon2.no_user_verify()
        {:error, :invalid_credentials}

      user ->
        if Argon2.verify_pass(password, user.password_hash) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end
    end
  end
end
