defmodule Core.User.Services.CreateUserService do
  @moduledoc """
  Service for creating users.

  This service handles the creation of new users by taking a validated
  `CreateUserCommand` and persisting it to the database as a `User` schema.
  """

  alias Core.Repo
  alias Core.Schemas.User
  alias Core.User.Commands.CreateUserCommand

  @spec execute(CreateUserCommand.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def execute(%CreateUserCommand{} = command),
    do:
      %{
        full_name: command.full_name,
        email: command.email,
        password: command.password
      }
      |> User.changeset()
      |> Repo.insert()
end
