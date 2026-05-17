defmodule Core.Conversation.Commands.SendMessageCommand do
  @moduledoc """
  Command for sending a user message in a conversation.

  ## Fields

  - `conversation_id` - UUID of the target conversation (required)
  - `user_id` - UUID of the authenticated user, used to verify conversation ownership (required)
  - `content` - The message text (required, 1–10 000 characters)
  """

  use Core.EmbeddedSchema

  @required_params [:conversation_id, :user_id, :content]

  @type t :: %__MODULE__{
          conversation_id: String.t(),
          user_id: String.t(),
          content: String.t()
        }

  embedded_schema do
    field :conversation_id, :string
    field :user_id, :string
    field :content, :string
  end

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(params),
    do:
      %__MODULE__{}
      |> cast(params, @required_params)
      |> validate_required(@required_params)
      |> validate_length(:content, min: 1, max: 10_000)
end
