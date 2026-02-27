defmodule Core.User.Services.ListUsersServiceTest do
  use Core.DataCase, async: true

  alias Core.User.Services.ListUsersService

  describe "execute/0" do
    test "returns empty list when there are no users" do
      assert [] = ListUsersService.execute()
    end

    test "returns all users" do
      user = insert(:user)

      assert [result] = ListUsersService.execute()
      assert result.id == user.id
    end

    test "returns users ordered by insertion date, most recent first" do
      first = insert(:user)
      second = insert(:user)

      assert [most_recent, oldest] = ListUsersService.execute()
      assert most_recent.id == second.id
      assert oldest.id == first.id
    end
  end
end
