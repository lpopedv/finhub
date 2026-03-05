defmodule Core.Category.Services.DeleteCategoryServiceTest do
  use Core.DataCase, async: true

  alias Core.Category.Services.DeleteCategoryService
  alias Core.Schemas.Category

  setup do
    %{category: insert(:category)}
  end

  describe "execute/1" do
    test "deletes the category and returns it", %{category: category} do
      assert {:ok, deleted} = DeleteCategoryService.execute(category.id)
      assert deleted.id == category.id
    end

    test "removes the category from the database", %{category: category} do
      DeleteCategoryService.execute(category.id)

      refute Repo.get(Category, category.id)
    end

    test "returns error when category is not found" do
      assert {:error, :not_found} = DeleteCategoryService.execute(Uniq.UUID.uuid7())
    end
  end
end
