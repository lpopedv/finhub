defmodule Core.Schemas.AiAgentTest do
  use Core.DataCase, async: true

  alias Core.Schemas.AiAgent

  describe "changeset/2" do
    setup do
      user = insert(:user)

      required_params = %{
        user_id: user.id,
        name: "Investment Advisor"
      }

      %{required_params: required_params, user: user}
    end

    test "returns a valid changeset with valid attributes", %{required_params: params} do
      changeset = AiAgent.changeset(params)
      assert changeset.valid?
    end

    test "returns a valid changeset with description", %{required_params: params} do
      changeset = AiAgent.changeset(Map.put(params, :description, "Focuses on investments"))
      assert changeset.valid?
    end

    for field <- [:user_id, :name] do
      test "returns invalid changeset when #{field} is missing", %{required_params: params} do
        invalid_params = Map.delete(params, unquote(field))

        changeset = AiAgent.changeset(invalid_params)

        refute changeset.valid?
        assert "can't be blank" in errors_on(changeset)[unquote(field)]
      end
    end

    test "validates name max length", %{required_params: params} do
      invalid = %{params | name: String.duplicate("a", 256)}

      changeset = AiAgent.changeset(invalid)

      refute changeset.valid?
      assert "should be at most 255 character(s)" in errors_on(changeset)[:name]
    end

    test "defaults deleted to false", %{required_params: params} do
      changeset = AiAgent.changeset(params)

      assert changeset.valid?
      assert get_field(changeset, :deleted) == false
    end

    test "successfully persists valid changeset to database", %{required_params: params} do
      assert %AiAgent{name: "Investment Advisor"} =
               params
               |> AiAgent.changeset()
               |> Repo.insert!()
    end

    test "allows multiple agents with the same name for the same user", %{
      required_params: params,
      user: user
    } do
      insert(:ai_agent, user: user, name: params.name)

      assert {:ok, _agent} =
               %AiAgent{}
               |> AiAgent.changeset(params)
               |> Repo.insert()
    end
  end
end
