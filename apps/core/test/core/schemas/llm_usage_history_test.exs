defmodule Core.Schemas.LlmUsageHistoryTest do
  use Core.DataCase, async: true

  alias Core.Schemas.LlmUsageHistory

  describe "changeset/2" do
    setup do
      user = insert(:user)
      conversation = insert(:conversation, user: user)

      message =
        insert(:message,
          conversation: conversation,
          role: :assistant,
          llm_model: "claude-sonnet-4-6",
          status: :completed
        )

      required_params = %{
        user_id: user.id,
        conversation_id: conversation.id,
        message_id: message.id,
        model: "claude-sonnet-4-6"
      }

      %{required_params: required_params}
    end

    test "returns a valid changeset with valid attributes", %{required_params: params} do
      changeset = LlmUsageHistory.changeset(params)
      assert changeset.valid?
    end

    test "returns a valid changeset with token counts", %{required_params: params} do
      changeset =
        LlmUsageHistory.changeset(
          Map.merge(params, %{input_tokens: 500, cached_input_tokens: 200, output_tokens: 150})
        )

      assert changeset.valid?
    end

    for field <- [:user_id, :conversation_id, :message_id, :model] do
      test "returns invalid changeset when #{field} is missing", %{required_params: params} do
        invalid_params = Map.delete(params, unquote(field))

        changeset = LlmUsageHistory.changeset(invalid_params)

        refute changeset.valid?
        assert "can't be blank" in errors_on(changeset)[unquote(field)]
      end
    end

    for field <- [:input_tokens, :cached_input_tokens, :output_tokens] do
      test "returns invalid changeset when #{field} is negative", %{required_params: params} do
        changeset = LlmUsageHistory.changeset(Map.put(params, unquote(field), -1))

        refute changeset.valid?
        assert "must be greater than or equal to 0" in errors_on(changeset)[unquote(field)]
      end
    end

    test "defaults token counts to 0", %{required_params: params} do
      changeset = LlmUsageHistory.changeset(params)

      assert changeset.valid?
      assert get_field(changeset, :input_tokens) == 0
      assert get_field(changeset, :cached_input_tokens) == 0
      assert get_field(changeset, :output_tokens) == 0
    end

    test "has no updated_at field" do
      refute :updated_at in LlmUsageHistory.__schema__(:fields)
    end

    test "successfully persists valid changeset to database", %{required_params: params} do
      assert %LlmUsageHistory{model: "claude-sonnet-4-6"} =
               params
               |> LlmUsageHistory.changeset()
               |> Repo.insert!()
    end
  end
end
