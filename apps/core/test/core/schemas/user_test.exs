defmodule Core.Schemas.UserTest do
  use Core.DataCase, async: true

  alias Core.Schemas.User

  describe "changeset/2" do
    setup do
      required_params = %{
        full_name: "Test User",
        email: "testuser@example.com",
        password: "password123"
      }

      %{required_params: required_params}
    end

    test "returns a valid changeset with valid attributes", %{required_params: params} do
      changeset = User.changeset(params)
      assert changeset.valid?
    end

    for field <- [:full_name, :email] do
      test "returns invalid changeset when #{field} is missing", %{required_params: params} do
        invalid_params = Map.delete(params, unquote(field))

        changeset = User.changeset(invalid_params)

        refute changeset.valid?
        assert "can't be blank" in errors_on(changeset)[unquote(field)]
      end
    end

    test "returns invalid changeset when password is missing for new user", %{
      required_params: params
    } do
      invalid_params = Map.delete(params, :password)

      changeset = User.changeset(invalid_params)

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset)[:password]
    end

    test "returns error when email is not unique", %{required_params: params} do
      %User{}
      |> User.changeset(params)
      |> Repo.insert!()

      assert {:error, changeset} =
               %User{}
               |> User.changeset(params)
               |> Repo.insert()

      assert "has already been taken" in errors_on(changeset)[:email]
    end

    test "validates full_name length", %{required_params: params} do
      invalid = %{params | full_name: String.duplicate("a", 151)}

      changeset = User.changeset(invalid)

      refute changeset.valid?
      assert "should be at most 150 character(s)" in errors_on(changeset)[:full_name]
    end

    test "validates email length", %{required_params: params} do
      long_email = String.duplicate("a", 140) <> "@example.com"
      invalid = %{params | email: long_email}

      changeset = User.changeset(invalid)

      refute changeset.valid?
      assert "should be at most 150 character(s)" in errors_on(changeset)[:email]
    end

    test "validates password minimum length", %{required_params: params} do
      invalid = %{params | password: "1234567"}

      changeset = User.changeset(invalid)

      refute changeset.valid?
      assert "should be at least 8 character(s)" in errors_on(changeset)[:password]
    end

    test "generates password_hash when password is provided", %{required_params: params} do
      changeset = User.changeset(params)

      assert changeset.valid?
      assert get_change(changeset, :password_hash)
      assert Argon2.verify_pass(params.password, get_change(changeset, :password_hash))
    end

    test "does not require password when updating existing user with password_hash", %{
      required_params: params
    } do
      {:ok, user} =
        %User{}
        |> User.changeset(params)
        |> Repo.insert()

      update_params = %{full_name: "Updated Name"}
      changeset = User.changeset(user, update_params)

      assert changeset.valid?
      refute get_change(changeset, :password_hash)
    end

    test "successfully persists valid changeset to database", %{required_params: params} do
      assert %User{password_hash: _hash} =
               params
               |> User.changeset()
               |> Repo.insert!()
    end
  end
end
