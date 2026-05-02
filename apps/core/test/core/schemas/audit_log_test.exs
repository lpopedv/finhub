defmodule Core.Schemas.AuditLogTest do
  use Core.DataCase, async: true

  alias Core.Schemas.AuditLog

  describe "changeset/2" do
    setup do
      user = insert(:user)

      required_params = %{
        actor_id: user.id,
        action: "ai_agent.create",
        resource_type: "AiAgent",
        resource_id: Ecto.UUID.generate()
      }

      %{required_params: required_params}
    end

    test "returns a valid changeset with valid attributes", %{required_params: params} do
      changeset = AuditLog.changeset(params)
      assert changeset.valid?
    end

    test "returns a valid changeset with changes and metadata", %{required_params: params} do
      changeset =
        AuditLog.changeset(
          Map.merge(params, %{
            changes: [%{field: "name", old: "Old Name", new: "New Name"}],
            metadata: %{ip: "127.0.0.1"}
          })
        )

      assert changeset.valid?
    end

    for field <- [:actor_id, :action, :resource_type, :resource_id] do
      test "returns invalid changeset when #{field} is missing", %{required_params: params} do
        invalid_params = Map.delete(params, unquote(field))

        changeset = AuditLog.changeset(invalid_params)

        refute changeset.valid?
        assert "can't be blank" in errors_on(changeset)[unquote(field)]
      end
    end

    test "has no updated_at field" do
      refute :updated_at in AuditLog.__schema__(:fields)
    end

    test "successfully persists valid changeset to database", %{required_params: params} do
      assert %AuditLog{action: "ai_agent.create"} =
               params
               |> AuditLog.changeset()
               |> Repo.insert!()
    end

    test "persists changes as a list of maps", %{required_params: params} do
      changes = [%{"field" => "name", "old" => "A", "new" => "B"}]

      assert %AuditLog{changes: ^changes} =
               params
               |> Map.put(:changes, changes)
               |> AuditLog.changeset()
               |> Repo.insert!()
    end
  end
end
