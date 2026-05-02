defmodule Core.Schemas.AiAgentPrompt do
  @moduledoc """
  Schema representing a versioned system prompt for an AI agent.

  Each agent can have multiple prompt versions, but only one is active at a time.
  The unique partial index on [ai_agent_id] WHERE active = true enforces this at the
  database level. Versions can be forked from a previous one via base_version_id,
  allowing lineage tracking.
  """

  use Core.Schema

  alias Core.Schemas.AiAgent

  @required_params [:ai_agent_id, :content, :version]
  @optional_params [:active, :became_active_at, :base_version_id]

  @type t :: %__MODULE__{
          id: Uniq.UUID.formatted(),
          ai_agent_id: Uniq.UUID.formatted(),
          content: String.t(),
          version: integer(),
          active: boolean(),
          became_active_at: DateTime.t() | nil,
          base_version_id: Uniq.UUID.formatted() | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t() | nil
        }

  schema "ai_agent_prompts" do
    field :content, :string
    field :version, :integer
    field :active, :boolean, default: false
    field :became_active_at, :utc_datetime_usec

    belongs_to :ai_agent, AiAgent
    belongs_to :base_version, __MODULE__, foreign_key: :base_version_id

    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(%__MODULE__{} | t(), map()) :: Ecto.Changeset.t()
  def changeset(schema \\ %__MODULE__{}, params),
    do:
      schema
      |> cast(params, @required_params ++ @optional_params)
      |> validate_required(@required_params)
      |> validate_number(:version, greater_than: 0)
      |> assoc_constraint(:ai_agent)
      |> unique_constraint(:version, name: :ai_agent_prompts_ai_agent_id_version_index)
      |> unique_constraint(:active,
        name: :ai_agent_prompts_one_active_per_agent_index,
        message: "another prompt is already active for this agent"
      )
end
