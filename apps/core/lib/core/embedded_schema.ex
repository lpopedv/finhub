defmodule Core.EmbeddedSchema do
  @moduledoc """
  Define common module attributes for Ecto embedded schemas
  """

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key false

      def build!(params) do
        case __MODULE__.changeset(params) do
          %Ecto.Changeset{valid?: false} = invalid_changeset ->
            raise Ecto.InvalidChangesetError,
              changeset: invalid_changeset,
              action: invalid_changeset.action

          valid_changeset ->
            apply_changes(valid_changeset)
        end
      end

      def build(params) do
        {:ok, build!(params)}
      rescue
        error in Ecto.InvalidChangesetError ->
          {:error, error.changeset}
      end
    end
  end
end
