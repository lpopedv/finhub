defmodule Core.Schemas.ConversationTest do
  use Core.DataCase, async: true

  alias Core.Schemas.Conversation

  describe "changeset/2" do
    setup do
      user = insert(:user)

      required_params = %{
        user_id: user.id
      }

      %{required_params: required_params, user: user}
    end

    test "returns a valid changeset with valid attributes", %{required_params: params} do
      changeset = Conversation.changeset(params)
      assert changeset.valid?
    end

    test "returns a valid changeset with an agent", %{required_params: params, user: user} do
      agent = insert(:ai_agent, user: user)
      changeset = Conversation.changeset(Map.put(params, :ai_agent_id, agent.id))
      assert changeset.valid?
    end

    test "returns a valid changeset with a title", %{required_params: params} do
      changeset = Conversation.changeset(Map.put(params, :title, "My finances"))
      assert changeset.valid?
    end

    test "returns invalid changeset when user_id is missing" do
      changeset = Conversation.changeset(%{})

      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset)[:user_id]
    end

    test "validates title max length", %{required_params: params} do
      invalid = Map.put(params, :title, String.duplicate("a", 256))

      changeset = Conversation.changeset(invalid)

      refute changeset.valid?
      assert "should be at most 255 character(s)" in errors_on(changeset)[:title]
    end

    test "defaults active to true", %{required_params: params} do
      changeset = Conversation.changeset(params)

      assert changeset.valid?
      assert get_field(changeset, :active) == true
    end

    test "allows ai_agent_id to be nil (general chat)", %{required_params: params} do
      changeset = Conversation.changeset(Map.put(params, :ai_agent_id, nil))
      assert changeset.valid?
    end

    test "agent is set to nil when agent is deleted", %{required_params: params, user: user} do
      agent = insert(:ai_agent, user: user)

      {:ok, conversation} =
        params
        |> Map.put(:ai_agent_id, agent.id)
        |> Conversation.changeset()
        |> Repo.insert()

      Repo.delete!(agent)

      updated = Repo.get!(Conversation, conversation.id)
      refute updated.ai_agent_id
    end

    test "successfully persists valid changeset to database", %{required_params: params} do
      assert %Conversation{active: true} =
               params
               |> Conversation.changeset()
               |> Repo.insert!()
    end
  end
end
