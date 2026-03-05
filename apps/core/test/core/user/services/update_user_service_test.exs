defmodule Core.User.Services.UpdateUserServiceTest do
  use Core.DataCase, async: true

  alias Core.User.Services.UpdateUserService

  setup do
    %{user: insert(:user)}
  end

  describe "execute/2" do
    test "updates full_name", %{user: user} do
      assert {:ok, updated} = UpdateUserService.execute(user.id, %{full_name: "Jane Doe"})
      assert updated.full_name == "Jane Doe"
    end

    test "updates email", %{user: user} do
      assert {:ok, updated} = UpdateUserService.execute(user.id, %{email: "jane@example.com"})
      assert updated.email == "jane@example.com"
    end

    test "updates password and rehashes it", %{user: user} do
      assert {:ok, updated} = UpdateUserService.execute(user.id, %{password: "newpassword123"})

      assert updated.password_hash != user.password_hash
      assert Argon2.verify_pass("newpassword123", updated.password_hash)
    end

    test "returns error when user is not found" do
      assert {:error, :not_found} =
               UpdateUserService.execute(Uniq.UUID.uuid7(), %{full_name: "Ghost"})
    end

    test "returns error when email is already taken", %{user: user} do
      other = insert(:user)

      assert {:error, changeset} = UpdateUserService.execute(user.id, %{email: other.email})
      assert "has already been taken" in errors_on(changeset).email
    end
  end
end
