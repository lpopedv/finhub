defmodule Core.Category.Services.CreateCategoryServiceTest do
  use Core.DataCase, async: true

  alias Core.Category.Commands.CreateCategoryCommand
  alias Core.Category.Services.CreateCategoryService
  alias Core.Schemas.Category

  setup do
    user = insert(:user)

    command =
      CreateCategoryCommand.build!(%{
        user_id: user.id,
        name: "Food"
      })

    %{command: command, user: user}
  end

  describe "execute/1" do
    test "creates and returns the category on success", %{command: command} do
      assert {:ok, %Category{} = category} = CreateCategoryService.execute(command)

      assert category.id
      assert category.user_id == command.user_id
      assert category.name == command.name
    end

    test "persists the category to the database", %{command: command} do
      {:ok, category} = CreateCategoryService.execute(command)

      assert Repo.get(Category, category.id)
    end

    test "returns error when name is already taken for the same user", %{command: command} do
      CreateCategoryService.execute(command)

      assert {:error, changeset} = CreateCategoryService.execute(command)
      assert "has already been taken" in errors_on(changeset).name
    end
  end
end
