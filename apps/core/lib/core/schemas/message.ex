defmodule Core.Schemas.Message do
  @moduledoc """
  Schema representing a single message in a conversation.

  Role identifies who sent the message (:user or :assistant). Status tracks
  the generation lifecycle — assistant messages start as :pending while the
  LLM is processing and transition to :completed or :error. User messages are
  always inserted as :completed.

  Token fields (llm_model, input_tokens, cached_input_tokens, output_tokens)
  are only populated for role: :assistant messages.
  """

  use Core.Schema

  alias Core.Schemas.Conversation

  @required_params [:conversation_id, :role, :content, :status]
  @optional_params [:llm_model, :input_tokens, :cached_input_tokens, :output_tokens]

  @type t :: %__MODULE__{
          id: Uniq.UUID.formatted(),
          conversation_id: Uniq.UUID.formatted(),
          role: :user | :assistant,
          content: String.t(),
          status: :pending | :completed | :error,
          llm_model: String.t() | nil,
          input_tokens: integer() | nil,
          cached_input_tokens: integer() | nil,
          output_tokens: integer() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t() | nil
        }

  schema "messages" do
    field :role, Ecto.Enum, values: [:user, :assistant]
    field :content, :string
    field :status, Ecto.Enum, values: [:pending, :completed, :error]
    field :llm_model, :string
    field :input_tokens, :integer
    field :cached_input_tokens, :integer
    field :output_tokens, :integer

    belongs_to :conversation, Conversation

    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(%__MODULE__{} | t(), map()) :: Ecto.Changeset.t()
  def changeset(schema \\ %__MODULE__{}, params),
    do:
      schema
      |> cast(params, @required_params ++ @optional_params)
      |> validate_required(@required_params)
      |> assoc_constraint(:conversation)
      |> check_constraint(:llm_model,
        name: :llm_model_required_for_assistant,
        message: "is required for assistant messages"
      )
      |> check_constraint(:status,
        name: :user_message_always_completed,
        message: "must be completed for user messages"
      )
end
