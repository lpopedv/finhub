defmodule Core.Schemas.LlmUsageHistory do
  @moduledoc """
  Schema representing a single LLM API call and its token consumption.

  Append-only — records are never updated or deleted (soft or otherwise).
  Each assistant message that completes successfully produces one record here.
  Used for usage analytics, cost tracking per model, and per-user billing audits.
  """

  use Core.Schema

  alias Core.Schemas.Conversation
  alias Core.Schemas.Message
  alias Core.Schemas.User

  @required_params [:user_id, :conversation_id, :message_id, :model]
  @optional_params [:input_tokens, :cached_input_tokens, :output_tokens]

  @type t :: %__MODULE__{
          id: Uniq.UUID.formatted(),
          user_id: Uniq.UUID.formatted(),
          conversation_id: Uniq.UUID.formatted(),
          message_id: Uniq.UUID.formatted(),
          model: String.t(),
          input_tokens: integer(),
          cached_input_tokens: integer(),
          output_tokens: integer(),
          inserted_at: DateTime.t()
        }

  schema "llm_usage_history" do
    field :model, :string
    field :input_tokens, :integer, default: 0
    field :cached_input_tokens, :integer, default: 0
    field :output_tokens, :integer, default: 0

    belongs_to :user, User
    belongs_to :conversation, Conversation
    belongs_to :message, Message

    timestamps(updated_at: false)
  end

  @spec changeset(%__MODULE__{} | t(), map()) :: Ecto.Changeset.t()
  def changeset(schema \\ %__MODULE__{}, params),
    do:
      schema
      |> cast(params, @required_params ++ @optional_params)
      |> validate_required(@required_params)
      |> validate_number(:input_tokens, greater_than_or_equal_to: 0)
      |> validate_number(:cached_input_tokens, greater_than_or_equal_to: 0)
      |> validate_number(:output_tokens, greater_than_or_equal_to: 0)
      |> assoc_constraint(:user)
      |> assoc_constraint(:conversation)
      |> assoc_constraint(:message)
end
