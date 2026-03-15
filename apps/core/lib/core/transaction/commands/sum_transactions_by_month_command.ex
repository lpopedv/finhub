defmodule Core.Transaction.Commands.SumTransactionsByMonthCommand do
  @moduledoc """
  Command for summing transactions grouped by month.

  ## Fields

  - `user_id` - UUID of the owning user (required)
  - `date_start` - Start of the date range (required)
  - `date_end` - End of the date range (required)
  - `type` - Optional filter by transaction type (`:expense` or `:income`)
  """

  use Core.EmbeddedSchema

  alias Core.TransactionType

  @required_params [:user_id, :date_start, :date_end]
  @optional_params [:type]

  @type t :: %__MODULE__{
          user_id: String.t(),
          date_start: Date.t(),
          date_end: Date.t(),
          type: TransactionType.t() | nil
        }

  embedded_schema do
    field(:user_id, :string)
    field(:date_start, :date)
    field(:date_end, :date)
    field(:type, Ecto.Enum, values: TransactionType.types())
  end

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(params),
    do:
      %__MODULE__{}
      |> cast(params, @required_params ++ @optional_params)
      |> validate_required(@required_params)
end
