defmodule Core.Audit do
  @moduledoc """
  Appends an audit log entry within the current Ecto transaction.

  Must be called inside `Ecto.Multi` or an open `Repo.transaction/1` block
  so the audit entry is committed atomically with the domain change.

  ## Usage

      Core.Audit.log(%{
        actor: actor,
        action: "ai_agent.create",
        resource_type: "AiAgent",
        resource_id: agent.id,
        changes: [%{field: "name", old: nil, new: "Consultor"}]
      })

  actor is a `Core.Audit.Actor` struct.
  action follows the "resource.operation" format.
  changes is a list of `%{field, old, new}` maps — omit if no field-level diff applies.
  metadata is a free-form map for extra context (IP, request ID, etc.).
  """

  alias Core.Audit.Actor
  alias Core.Repo
  alias Core.Schemas.AuditLog

  @type log_params :: %{
          required(:actor) => Actor.t(),
          required(:action) => String.t(),
          required(:resource_type) => String.t(),
          required(:resource_id) => Ecto.UUID.t(),
          optional(:changes) => [map()] | nil,
          optional(:metadata) => map() | nil
        }

  @spec log(log_params()) :: {:ok, AuditLog.t()} | {:error, Ecto.Changeset.t()}
  def log(%{actor: %Actor{} = actor} = params) do
    %{
      actor_id: actor.actor_id,
      action: params.action,
      resource_type: params.resource_type,
      resource_id: params.resource_id,
      changes: Map.get(params, :changes),
      metadata: Map.get(params, :metadata)
    }
    |> AuditLog.changeset()
    |> Repo.insert()
  end
end
