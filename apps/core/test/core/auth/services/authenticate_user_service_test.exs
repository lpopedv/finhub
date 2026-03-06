defmodule Core.Auth.Services.AuthenticateUserServiceTest do
  use Core.DataCase, async: true

  alias Core.Auth.Commands.AuthenticateUserCommand
  alias Core.Auth.Services.AuthenticateUserService
  alias Core.Schemas.User
  alias Core.User.Commands.CreateUserCommand
  alias Core.User.Services.CreateUserService

  setup do
    {:ok, user} =
      CreateUserCommand.build!(%{
        full_name: "John Doe",
        email: "john@example.com",
        password: "password123"
      })
      |> CreateUserService.execute()

    %{user: user}
  end

  describe "execute/1" do
    test "returns the user on valid credentials", %{user: user} do
      command = AuthenticateUserCommand.build!(%{email: user.email, password: "password123"})

      assert {:ok, %User{} = authenticated} = AuthenticateUserService.execute(command)
      assert authenticated.id == user.id
    end

    test "returns error on wrong password", %{user: user} do
      command = AuthenticateUserCommand.build!(%{email: user.email, password: "wrongpassword"})

      assert {:error, :invalid_credentials} = AuthenticateUserService.execute(command)
    end

    test "returns error when user does not exist" do
      command = AuthenticateUserCommand.build!(%{email: "ghost@example.com", password: "password123"})

      assert {:error, :invalid_credentials} = AuthenticateUserService.execute(command)
    end
  end
end
