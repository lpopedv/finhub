defmodule Core.Schemas.TransactionTest do
  use Core.DataCase, async: true

  alias Core.Schemas.Transaction

  describe "changeset/2" do
    setup do
      user = insert(:user)

      required_params = %{
        user_id: user.id,
        name: "Groceries",
        value_in_cents: 5000
      }

      %{required_params: required_params, user: user}
    end

    test "returns a valid changeset with valid attributes", %{required_params: params} do
      changeset = Transaction.changeset(params)
      assert changeset.valid?
    end

    test "returns a valid changeset with category", %{required_params: params, user: user} do
      category = insert(:category, user: user)
      changeset = Transaction.changeset(Map.put(params, :category_id, category.id))
      assert changeset.valid?
    end

    test "returns a valid changeset with is_fixed set to true", %{required_params: params} do
      changeset = Transaction.changeset(Map.put(params, :is_fixed, true))
      assert changeset.valid?
    end

    for field <- [:user_id, :name, :value_in_cents] do
      test "returns invalid changeset when #{field} is missing", %{required_params: params} do
        invalid_params = Map.delete(params, unquote(field))

        changeset = Transaction.changeset(invalid_params)

        refute changeset.valid?
        assert "can't be blank" in errors_on(changeset)[unquote(field)]
      end
    end

    test "validates name max length", %{required_params: params} do
      invalid = %{params | name: String.duplicate("a", 256)}

      changeset = Transaction.changeset(invalid)

      refute changeset.valid?
      assert "should be at most 255 character(s)" in errors_on(changeset)[:name]
    end

    test "validates value_in_cents must be greater than 0", %{required_params: params} do
      for value <- [0, -1] do
        changeset = Transaction.changeset(%{params | value_in_cents: value})

        refute changeset.valid?
        assert "must be greater than 0" in errors_on(changeset)[:value_in_cents]
      end
    end

    test "allows category_id to be nil", %{required_params: params} do
      changeset = Transaction.changeset(Map.put(params, :category_id, nil))
      assert changeset.valid?
    end

    test "successfully persists valid changeset to database", %{required_params: params} do
      assert %Transaction{name: "Groceries"} =
               params
               |> Transaction.changeset()
               |> Repo.insert!()
    end

    test "category is set to nil when category is deleted", %{
      required_params: params,
      user: user
    } do
      category = insert(:category, user: user)

      {:ok, transaction} =
        params
        |> Map.put(:category_id, category.id)
        |> Transaction.changeset()
        |> Repo.insert()

      Repo.delete!(category)

      updated = Repo.get!(Transaction, transaction.id)
      refute updated.category_id
    end
  end
end
