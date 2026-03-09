defmodule Core.FixedTransaction.Commands.CreateFixedTransactionCommand do
  @moduledoc """
  Command for creating a new fixed transaction rule.

  ## Fields

  - `user_id` - UUID of the owning user (required)
  - `name` - Fixed transaction name (required, max 255 characters)
  - `value_in_cents` - Value in cents, must be greater than 0 (required)
  - `day_of_month` - Day of the month the transaction recurs, between 1 and 28 (required)
  - `category_id` - UUID of the associated category (optional)
  """

  use Core.EmbeddedSchema

  @required_params [:user_id, :name, :value_in_cents, :day_of_month]
  @optional_params [:category_id]

  @type t :: %__MODULE__{
          user_id: String.t(),
          category_id: String.t() | nil,
          name: String.t(),
          value_in_cents: integer(),
          day_of_month: integer()
        }

  embedded_schema do
    field(:user_id, :string)
    field(:category_id, :string)
    field(:name, :string)
    field(:value_in_cents, :integer)
    field(:day_of_month, :integer)
  end

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(params),
    do:
      %__MODULE__{}
      |> cast(params, @required_params ++ @optional_params)
      |> validate_required(@required_params)
      |> validate_length(:name, min: 1, max: 255)
      |> validate_number(:value_in_cents, greater_than: 0)
      |> validate_inclusion(:day_of_month, 1..28)
end
