defmodule Core.Schema do
  @moduledoc """
  Defines commom module attributes for Core application Ecto schemas.
  """

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key {:id, Uniq.UUID, version: 7, autogenerate: true, type: :uuid}
      @timestamps_opts [type: :utc_datetime_usec]
      @foreign_key_type Uniq.UUID
    end
  end
end
