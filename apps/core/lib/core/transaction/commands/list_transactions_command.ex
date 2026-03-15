defmodule Core.Transaction.Commands.ListTransactionsCommand do
  @moduledoc """
  Command for listing transactions of a user.

  ## Fields

  - `user_id` - UUID of the owning user (required)
  - `search` - Optional free-text filter applied to transaction name and category name
  """

  use Core.EmbeddedSchema

  @required_params [:user_id]
  @optional_params [:search]

  @type t :: %__MODULE__{
          user_id: String.t(),
          search: String.t() | nil
        }

  embedded_schema do
    field(:user_id, :string)
    field(:search, :string)
  end

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(params),
    do:
      %__MODULE__{}
      |> cast(params, @required_params ++ @optional_params)
      |> validate_required(@required_params)
end
