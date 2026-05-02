defmodule Core.Schemas.AiAgentPromptTest do
  use Core.DataCase, async: true

  alias Core.Schemas.AiAgentPrompt

  describe "changeset/2" do
    setup do
      agent = insert(:ai_agent)

      required_params = %{
        ai_agent_id: agent.id,
        content: "You are a helpful financial assistant.",
        version: 1
      }

      %{required_params: required_params, agent: agent}
    end

    test "returns a valid changeset with valid attributes", %{required_params: params} do
      changeset = AiAgentPrompt.changeset(params)
      assert changeset.valid?
    end

    test "returns a valid changeset with active set to true", %{required_params: params} do
      changeset =
        AiAgentPrompt.changeset(
          Map.merge(params, %{active: true, became_active_at: DateTime.utc_now()})
        )

      assert changeset.valid?
    end

    test "returns a valid changeset with base_version_id (fork)", %{
      required_params: params,
      agent: agent
    } do
      base = insert(:ai_agent_prompt, ai_agent: agent, version: 1)

      changeset =
        AiAgentPrompt.changeset(Map.merge(params, %{version: 2, base_version_id: base.id}))

      assert changeset.valid?
    end

    for field <- [:ai_agent_id, :content, :version] do
      test "returns invalid changeset when #{field} is missing", %{required_params: params} do
        invalid_params = Map.delete(params, unquote(field))

        changeset = AiAgentPrompt.changeset(invalid_params)

        refute changeset.valid?
        assert "can't be blank" in errors_on(changeset)[unquote(field)]
      end
    end

    test "validates version must be greater than 0", %{required_params: params} do
      for v <- [0, -1] do
        changeset = AiAgentPrompt.changeset(%{params | version: v})

        refute changeset.valid?
        assert "must be greater than 0" in errors_on(changeset)[:version]
      end
    end

    test "defaults active to false", %{required_params: params} do
      changeset = AiAgentPrompt.changeset(params)

      assert changeset.valid?
      assert get_field(changeset, :active) == false
    end

    test "returns error when version is not unique for the same agent", %{
      required_params: params,
      agent: agent
    } do
      insert(:ai_agent_prompt, ai_agent: agent, version: 1)

      assert {:error, changeset} =
               %AiAgentPrompt{}
               |> AiAgentPrompt.changeset(params)
               |> Repo.insert()

      assert "has already been taken" in errors_on(changeset)[:version]
    end

    test "allows same version number for different agents", %{required_params: params} do
      other_agent = insert(:ai_agent)
      insert(:ai_agent_prompt, ai_agent: other_agent, version: 1)

      assert {:ok, _prompt} =
               %AiAgentPrompt{}
               |> AiAgentPrompt.changeset(params)
               |> Repo.insert()
    end

    test "returns error when a second active prompt is inserted for the same agent", %{
      required_params: params,
      agent: agent
    } do
      insert(:ai_agent_prompt, ai_agent: agent, version: 1, active: true)

      assert {:error, changeset} =
               %AiAgentPrompt{}
               |> AiAgentPrompt.changeset(Map.merge(params, %{version: 2, active: true}))
               |> Repo.insert()

      assert "another prompt is already active for this agent" in errors_on(changeset)[:active]
    end

    test "successfully persists valid changeset to database", %{required_params: params} do
      assert %AiAgentPrompt{version: 1} =
               params
               |> AiAgentPrompt.changeset()
               |> Repo.insert!()
    end
  end
end
