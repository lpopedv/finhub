defmodule Core.Conversation.Services.SendMessageServiceTest do
  use Core.DataCase, async: true
  use Oban.Testing, repo: Core.Repo

  alias Core.Conversation.Commands.SendMessageCommand
  alias Core.Conversation.Services.SendMessageService
  alias Core.Conversation.Workers.GenerateResponseWorker
  alias Core.Schemas.Conversation
  alias Core.Schemas.Message

  describe "execute/1" do
    setup do
      user = insert(:user)
      conversation = insert(:conversation, user: user)

      command =
        SendMessageCommand.build!(%{
          conversation_id: conversation.id,
          user_id: user.id,
          content: "What is my current balance?"
        })

      %{command: command, user: user, conversation: conversation}
    end
    test "returns the user message on success", %{command: command} do
      assert {:ok, %Message{} = message} = SendMessageService.execute(command)

      assert message.id
      assert message.conversation_id == command.conversation_id
      assert message.role == :user
      assert message.status == :completed
      assert message.content == command.content
    end

    test "persists the user message to the database", %{command: command} do
      {:ok, message} = SendMessageService.execute(command)

      assert Repo.get(Message, message.id)
    end

    test "updates last_message_at on the conversation", %{command: command, conversation: conversation} do
      SendMessageService.execute(command)

      updated = Repo.get!(Conversation, conversation.id)
      assert updated.last_message_at
    end

    test "enqueues GenerateResponseWorker with correct args", %{command: command} do
      {:ok, message} = SendMessageService.execute(command)

      assert_enqueued(
        worker: GenerateResponseWorker,
        args: %{conversation_id: command.conversation_id, user_message_id: message.id}
      )
    end

    test "returns error when conversation does not exist", %{user: user} do
      command =
        SendMessageCommand.build!(%{
          conversation_id: Uniq.UUID.uuid7(),
          user_id: user.id,
          content: "Hello"
        })

      assert {:error, :conversation_not_found} = SendMessageService.execute(command)
      refute_enqueued(worker: GenerateResponseWorker)
    end

    test "returns error when conversation belongs to another user", %{conversation: conversation} do
      other_user = insert(:user)

      command =
        SendMessageCommand.build!(%{
          conversation_id: conversation.id,
          user_id: other_user.id,
          content: "Hello"
        })

      assert {:error, :conversation_not_found} = SendMessageService.execute(command)
      refute_enqueued(worker: GenerateResponseWorker)
    end

    test "returns error when conversation is inactive", %{user: user} do
      inactive = insert(:conversation, user: user, active: false)

      command =
        SendMessageCommand.build!(%{
          conversation_id: inactive.id,
          user_id: user.id,
          content: "Hello"
        })

      assert {:error, :conversation_not_found} = SendMessageService.execute(command)
      refute_enqueued(worker: GenerateResponseWorker)
    end
  end
end
