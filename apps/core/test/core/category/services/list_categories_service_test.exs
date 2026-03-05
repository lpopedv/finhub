defmodule Core.Category.Services.ListCategoriesServiceTest do
  use Core.DataCase, async: true

  alias Core.Category.Services.ListCategoriesService

  setup do
    %{user: insert(:user)}
  end

  describe "execute/1" do
    test "returns empty list when user has no categories", %{user: user} do
      assert [] = ListCategoriesService.execute(user.id)
    end

    test "returns only categories belonging to the user", %{user: user} do
      category = insert(:category, user: user)
      insert(:category)

      assert [result] = ListCategoriesService.execute(user.id)
      assert result.id == category.id
    end

    test "returns categories ordered by insertion date, most recent first", %{user: user} do
      first = insert(:category, user: user)
      second = insert(:category, user: user)

      assert [most_recent, oldest] = ListCategoriesService.execute(user.id)
      assert most_recent.id == second.id
      assert oldest.id == first.id
    end
  end
end
