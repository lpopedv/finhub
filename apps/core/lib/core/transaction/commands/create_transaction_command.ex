defmodule Core.Transaction.Commands.CreateTransactionCommand do
  @moduledoc """
  Command for creating a new transaction.

  ## Fields

  - `user_id` - UUID of the owning user (required)
  - `name` - Transaction name (required, max 255 characters)
  - `value_in_cents` - Transaction value in cents, must be greater than 0 (required)
  - `date` - Date the transaction occurs or is due (required)
  - `category_id` - UUID of the associated category (optional)
  - `is_fixed` - Whether the transaction is a fixed expense (optional, defaults to false)
  """

  use Core.EmbeddedSchema

  @required_params [:user_id, :name, :value_in_cents, :date]
  @optional_params [:category_id, :is_fixed]

  @type t :: %__MODULE__{
          user_id: String.t(),
          category_id: String.t() | nil,
          name: String.t(),
          value_in_cents: integer(),
          is_fixed: boolean(),
          date: Date.t()
        }

  embedded_schema do
    field(:user_id, :string)
    field(:category_id, :string)
    field(:name, :string)
    field(:value_in_cents, :integer)
    field(:is_fixed, :boolean, default: false)
    field(:date, :date)
  end

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(params),
    do:
      %__MODULE__{}
      |> cast(params, @required_params ++ @optional_params)
      |> validate_required(@required_params)
      |> validate_length(:name, min: 1, max: 255)
      |> validate_number(:value_in_cents, greater_than: 0)
end
