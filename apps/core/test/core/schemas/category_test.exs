defmodule Core.Schemas.CategoryTest do
  use Core.DataCase, async: true

  alias Core.Schemas.Category

  describe "changeset/2" do
    setup do
      user = insert(:user)

      required_params = %{
        user_id: user.id,
        name: "Food"
      }

      %{required_params: required_params, user: user}
    end

    test "returns a valid changeset with valid attributes", %{required_params: params} do
      changeset = Category.changeset(params)
      assert changeset.valid?
    end

    test "returns a valid changeset with description", %{required_params: params} do
      changeset =
        Category.changeset(
          %{params | name: "Transport"}
          |> Map.put(:description, "Transport expenses")
        )

      assert changeset.valid?
    end

    for field <- [:user_id, :name] do
      test "returns invalid changeset when #{field} is missing", %{required_params: params} do
        invalid_params = Map.delete(params, unquote(field))

        changeset = Category.changeset(invalid_params)

        refute changeset.valid?
        assert "can't be blank" in errors_on(changeset)[unquote(field)]
      end
    end

    test "validates name max length", %{required_params: params} do
      invalid = %{params | name: String.duplicate("a", 101)}

      changeset = Category.changeset(invalid)

      refute changeset.valid?
      assert "should be at most 100 character(s)" in errors_on(changeset)[:name]
    end

    test "returns error when name is not unique for same user", %{
      required_params: params,
      user: user
    } do
      insert(:category, user: user, name: params.name)

      assert {:error, changeset} =
               %Category{}
               |> Category.changeset(params)
               |> Repo.insert()

      assert "has already been taken" in errors_on(changeset)[:name]
    end

    test "allows same name for different users", %{required_params: params} do
      other_user = insert(:user)
      insert(:category, user: other_user, name: params.name)

      assert {:ok, _category} =
               %Category{}
               |> Category.changeset(params)
               |> Repo.insert()
    end

    test "successfully persists valid changeset to database", %{required_params: params} do
      assert %Category{name: "Food"} =
               params
               |> Category.changeset()
               |> Repo.insert!()
    end
  end
end
