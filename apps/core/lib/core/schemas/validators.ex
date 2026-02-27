defmodule Core.Schemas.Validators do
  @moduledoc """
  Custom Ecto changeset validators shared across schemas and commands.
  """

  import Ecto.Changeset

  @email_regex ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/

  @doc """
  Validates that the given field contains a well-formed email address.
  """
  @spec validate_email(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def validate_email(changeset, field),
    do: validate_format(changeset, field, @email_regex, message: "has invalid format")
end
