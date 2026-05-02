defmodule Core.Schemas.MessageTest do
  use Core.DataCase, async: true

  alias Core.Schemas.Message

  describe "changeset/2" do
    setup do
      conversation = insert(:conversation)

      required_params = %{
        conversation_id: conversation.id,
        role: :user,
        content: "What is my current balance?",
        status: :completed
      }

      %{required_params: required_params, conversation: conversation}
    end

    test "returns a valid changeset for a user message", %{required_params: params} do
      changeset = Message.changeset(params)
      assert changeset.valid?
    end

    test "returns a valid changeset for an assistant message", %{required_params: params} do
      params =
        Map.merge(params, %{
          role: :assistant,
          status: :completed,
          llm_model: "claude-sonnet-4-6",
          input_tokens: 100,
          cached_input_tokens: 50,
          output_tokens: 200
        })

      changeset = Message.changeset(params)
      assert changeset.valid?
    end

    test "returns a valid changeset for a pending assistant message", %{required_params: params} do
      params =
        Map.merge(params, %{role: :assistant, status: :pending, llm_model: "claude-sonnet-4-6"})

      changeset = Message.changeset(params)
      assert changeset.valid?
    end

    for field <- [:conversation_id, :role, :content, :status] do
      test "returns invalid changeset when #{field} is missing", %{required_params: params} do
        invalid_params = Map.delete(params, unquote(field))

        changeset = Message.changeset(invalid_params)

        refute changeset.valid?
        assert "can't be blank" in errors_on(changeset)[unquote(field)]
      end
    end

    test "returns error for invalid role", %{required_params: params} do
      changeset = Message.changeset(%{params | role: :admin})

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset)[:role]
    end

    test "returns error for invalid status", %{required_params: params} do
      changeset = Message.changeset(%{params | status: :unknown})

      refute changeset.valid?
      assert "is invalid" in errors_on(changeset)[:status]
    end

    test "returns error when assistant message has no llm_model", %{required_params: params} do
      assert {:error, changeset} =
               params
               |> Map.merge(%{role: :assistant, status: :completed})
               |> Message.changeset()
               |> Repo.insert()

      assert "is required for assistant messages" in errors_on(changeset)[:llm_model]
    end

    test "returns error when user message has pending status", %{required_params: params} do
      assert {:error, changeset} =
               params
               |> Map.merge(%{role: :user, status: :pending})
               |> Message.changeset()
               |> Repo.insert()

      assert "must be completed for user messages" in errors_on(changeset)[:status]
    end

    test "successfully persists a user message to database", %{required_params: params} do
      assert %Message{role: :user, status: :completed} =
               params
               |> Message.changeset()
               |> Repo.insert!()
    end

    test "successfully persists an assistant message to database", %{required_params: params} do
      assert %Message{role: :assistant, status: :completed} =
               params
               |> Map.merge(%{
                 role: :assistant,
                 status: :completed,
                 llm_model: "claude-sonnet-4-6",
                 input_tokens: 100,
                 output_tokens: 200
               })
               |> Message.changeset()
               |> Repo.insert!()
    end
  end
end
