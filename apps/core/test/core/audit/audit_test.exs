defmodule Core.AuditTest do
  use Core.DataCase, async: true

  alias Core.Audit
  alias Core.Audit.Actor
  alias Core.Schemas.AuditLog

  setup do
    user = insert(:user)
    actor = Actor.build!(%{actor_id: user.id})

    %{
      actor: actor,
      resource_id: Uniq.UUID.uuid7()
    }
  end

  describe "log/1" do
    test "inserts an AuditLog record and returns it", %{actor: actor, resource_id: resource_id} do
      assert {:ok, %AuditLog{} = log} =
               Audit.log(%{
                 actor: actor,
                 action: "ai_agent.create",
                 resource_type: "AiAgent",
                 resource_id: resource_id
               })

      assert log.id
      assert log.actor_id == actor.actor_id
      assert log.action == "ai_agent.create"
      assert log.resource_type == "AiAgent"
      assert log.resource_id == resource_id
      assert log.changes == nil
      assert log.metadata == nil
    end

    test "persists the record to the database", %{actor: actor, resource_id: resource_id} do
      {:ok, log} =
        Audit.log(%{
          actor: actor,
          action: "ai_agent.create",
          resource_type: "AiAgent",
          resource_id: resource_id
        })

      assert Repo.get(AuditLog, log.id)
    end

    test "stores changes when provided", %{actor: actor, resource_id: resource_id} do
      changes = [%{field: "name", old: nil, new: "Consultor"}]

      assert {:ok, %AuditLog{changes: ^changes}} =
               Audit.log(%{
                 actor: actor,
                 action: "ai_agent.create",
                 resource_type: "AiAgent",
                 resource_id: resource_id,
                 changes: changes
               })
    end

    test "stores metadata when provided", %{actor: actor, resource_id: resource_id} do
      metadata = %{"ip" => "127.0.0.1"}

      assert {:ok, %AuditLog{metadata: ^metadata}} =
               Audit.log(%{
                 actor: actor,
                 action: "ai_agent.create",
                 resource_type: "AiAgent",
                 resource_id: resource_id,
                 metadata: metadata
               })
    end

    test "rolls back with the enclosing transaction on failure", %{
      actor: actor,
      resource_id: resource_id
    } do
      result =
        Repo.transaction(fn ->
          {:ok, _log} =
            Audit.log(%{
              actor: actor,
              action: "ai_agent.create",
              resource_type: "AiAgent",
              resource_id: resource_id
            })

          Repo.rollback(:forced)
        end)

      assert result == {:error, :forced}
      assert Repo.aggregate(AuditLog, :count) == 0
    end
  end
end
