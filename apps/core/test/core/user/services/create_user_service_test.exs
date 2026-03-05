defmodule Core.User.Services.CreateUserServiceTest do
  use Core.DataCase, async: true

  alias Core.Schemas.User
  alias Core.User.Commands.CreateUserCommand
  alias Core.User.Services.CreateUserService

  setup do
    command =
      CreateUserCommand.build!(%{
        full_name: "John Doe",
        email: "john@example.com",
        password: "password123"
      })

    %{command: command}
  end

  describe "execute/1" do
    test "creates and returns the user on success", %{command: command} do
      assert {:ok, %User{} = user} = CreateUserService.execute(command)

      assert user.id
      assert user.full_name == command.full_name
      assert user.email == command.email
      assert user.password_hash
    end

    test "persists the user to the database", %{command: command} do
      {:ok, user} = CreateUserService.execute(command)

      assert Repo.get(User, user.id)
    end

    test "returns error when email is already taken", %{command: command} do
      CreateUserService.execute(command)

      assert {:error, changeset} = CreateUserService.execute(command)
      assert "has already been taken" in errors_on(changeset).email
    end
  end
end
