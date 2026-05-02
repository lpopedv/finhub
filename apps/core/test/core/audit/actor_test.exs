defmodule Core.Audit.ActorTest do
  use ExUnit.Case, async: true

  alias Core.Audit.Actor

  describe "changeset/1" do
    test "returns valid changeset with actor_id" do
      changeset = Actor.changeset(%{actor_id: Uniq.UUID.uuid7()})
      assert changeset.valid?
    end

    test "defaults actor_type to :user" do
      actor = Actor.build!(%{actor_id: Uniq.UUID.uuid7()})
      assert actor.actor_type == :user
    end

    test "accepts explicit actor_type :user" do
      changeset = Actor.changeset(%{actor_id: Uniq.UUID.uuid7(), actor_type: :user})
      assert changeset.valid?
    end

    test "returns invalid changeset when actor_id is missing" do
      changeset = Actor.changeset(%{})
      refute changeset.valid?

      assert "can't be blank" in Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end).actor_id
    end
  end

  describe "build!/1" do
    test "returns struct on valid params" do
      actor = Actor.build!(%{actor_id: Uniq.UUID.uuid7()})
      assert %Actor{actor_type: :user} = actor
    end

    test "raises on invalid params" do
      assert_raise Ecto.InvalidChangesetError, fn ->
        Actor.build!(%{})
      end
    end
  end

  describe "build/1" do
    test "returns {:ok, actor} on valid params" do
      assert {:ok, %Actor{}} = Actor.build(%{actor_id: Uniq.UUID.uuid7()})
    end

    test "returns {:error, changeset} on invalid params" do
      assert {:error, %Ecto.Changeset{}} = Actor.build(%{})
    end
  end
end
