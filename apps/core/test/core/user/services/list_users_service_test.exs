defmodule Core.User.Services.ListUsersServiceTest do
  use Core.DataCase, async: true

  alias Core.Schemas.User
  alias Core.User.Services.ListUsersService

  defp insert_user(attrs \\ %{}) do
    defaults = %{
      full_name: "John Doe",
      email: "john@example.com",
      password: "password123"
    }

    %User{}
    |> User.changeset(Map.merge(defaults, attrs))
    |> Repo.insert!()
  end

  describe "execute/0" do
    test "returns empty list when there are no users" do
      assert [] = ListUsersService.execute()
    end

    test "returns all users" do
      user = insert_user()

      assert [result] = ListUsersService.execute()
      assert result.id == user.id
    end

    test "returns users ordered by insertion date, most recent first" do
      first = insert_user(%{email: "first@example.com"})
      second = insert_user(%{email: "second@example.com"})

      assert [most_recent, oldest] = ListUsersService.execute()
      assert most_recent.id == second.id
      assert oldest.id == first.id
    end
  end
end
