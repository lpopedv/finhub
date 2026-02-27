defmodule Core.Schemas.User do
  @moduledoc """
  Schema representing an application user.

  Stores identity and authentication data. The `password` field is virtual and
  never persisted — only the Argon2 hash is stored in `password_hash`.

  ## Password rules

  - Required on creation (when `password_hash` is nil)
  - Minimum 8 characters
  """

  use Core.Schema

  @required_params [:full_name, :email]
  @optional_params [:password]

  @type t :: %__MODULE__{
          id: Uniq.UUID.formatted(),
          full_name: String.t(),
          email: String.t(),
          password: String.t() | nil,
          password_hash: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t() | nil
        }

  schema "users" do
    field :full_name, :string
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string, redact: true

    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(%__MODULE__{} | t(), map()) :: Ecto.Changeset.t()
  def changeset(schema \\ %__MODULE__{}, params),
    do:
      schema
      |> cast(params, @required_params ++ @optional_params)
      |> validate_required(@required_params)
      |> validate_length(:full_name, max: 150)
      |> validate_length(:email, max: 150)
      |> unique_constraint(:email)
      |> validate_password()
      |> maybe_hash_password()

  defp validate_password(%{data: %{password_hash: nil}} = changeset),
    do:
      changeset
      |> validate_required([:password])
      |> validate_length(:password, min: 8)

  defp validate_password(changeset), do: changeset

  defp maybe_hash_password(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       )
       when is_binary(password) do
    put_change(changeset, :password_hash, Argon2.hash_pwd_salt(password))
  end

  defp maybe_hash_password(changeset), do: changeset
end
