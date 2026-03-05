defmodule Core.Category.Services.UpdateCategoryServiceTest do
  use Core.DataCase, async: true

  alias Core.Category.Services.UpdateCategoryService

  setup do
    %{category: insert(:category)}
  end

  describe "execute/2" do
    test "updates name", %{category: category} do
      assert {:ok, updated} = UpdateCategoryService.execute(category.id, %{name: "Transport"})
      assert updated.name == "Transport"
    end

    test "updates description", %{category: category} do
      assert {:ok, updated} =
               UpdateCategoryService.execute(category.id, %{description: "My expenses"})

      assert updated.description == "My expenses"
    end

    test "returns error when category is not found" do
      assert {:error, :not_found} =
               UpdateCategoryService.execute(Uniq.UUID.uuid7(), %{name: "Ghost"})
    end

    test "returns error when name is already taken for the same user", %{category: category} do
      other = insert(:category, user: category.user)

      assert {:error, changeset} =
               UpdateCategoryService.execute(category.id, %{name: other.name})

      assert "has already been taken" in errors_on(changeset).user_id
    end
  end
end
