defmodule Core.User.Services.DeleteUserServiceTest do
  use Core.DataCase, async: true

  alias Core.Schemas.User
  alias Core.User.Services.DeleteUserService

  setup do
    user =
      %User{}
      |> User.changeset(%{
        full_name: "John Doe",
        email: "john@example.com",
        password: "password123"
      })
      |> Repo.insert!()

    %{user: user}
  end

  describe "execute/1" do
    test "deletes the user and returns it", %{user: user} do
      assert {:ok, deleted} = DeleteUserService.execute(user.id)
      assert deleted.id == user.id
    end

    test "removes the user from the database", %{user: user} do
      DeleteUserService.execute(user.id)

      refute Repo.get(User, user.id)
    end

    test "returns error when user is not found" do
      assert {:error, :not_found} = DeleteUserService.execute(Uniq.UUID.uuid7())
    end
  end
end
