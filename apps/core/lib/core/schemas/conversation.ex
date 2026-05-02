defmodule Core.Schemas.Conversation do
  @moduledoc """
  Schema representing a chat session between a user and an AI agent.

  A conversation can be tied to a specific agent persona (ai_agent_id) or left
  as a general chat (ai_agent_id: nil). The active flag is set to false when
  the user archives a conversation.

  The context_built_until_message_id field is added via a later migration once
  the messages table exists, since the two tables have a circular dependency.
  """

  use Core.Schema

  alias Core.Schemas.AiAgent
  alias Core.Schemas.Message
  alias Core.Schemas.User

  @required_params [:user_id]
  @optional_params [
    :ai_agent_id,
    :title,
    :active,
    :last_message_at,
    :context_built_until_message_id
  ]

  @type t :: %__MODULE__{
          id: Uniq.UUID.formatted(),
          user_id: Uniq.UUID.formatted(),
          ai_agent_id: Uniq.UUID.formatted() | nil,
          context_built_until_message_id: Uniq.UUID.formatted() | nil,
          title: String.t() | nil,
          active: boolean(),
          last_message_at: DateTime.t() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t() | nil
        }

  schema "conversations" do
    field :title, :string
    field :active, :boolean, default: true
    field :last_message_at, :utc_datetime_usec

    belongs_to :user, User
    belongs_to :ai_agent, AiAgent
    belongs_to :context_built_until_message, Message, foreign_key: :context_built_until_message_id

    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(%__MODULE__{} | t(), map()) :: Ecto.Changeset.t()
  def changeset(schema \\ %__MODULE__{}, params),
    do:
      schema
      |> cast(params, @required_params ++ @optional_params)
      |> validate_required(@required_params)
      |> validate_length(:title, max: 255)
      |> assoc_constraint(:user)
      |> assoc_constraint(:ai_agent)
end
