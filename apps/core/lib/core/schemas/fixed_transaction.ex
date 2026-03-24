defmodule Core.Schemas.FixedTransaction do
  @moduledoc """
  Schema representing a recurring transaction rule.

  Fixed transactions define recurring expenses or income by day of month.
  Concrete transaction entries reference this via `fixed_transaction_id`.
  Values are stored in cents to avoid floating-point precision issues.
  When the associated category is deleted, `category_id` is set to nil.
  """

  use Core.Schema

  alias Core.Schemas.Category
  alias Core.Schemas.User
  alias Core.TransactionType

  @required_params [:user_id, :name, :value_in_cents, :day_of_month, :type]
  @optional_params [:category_id, :active]

  @type t :: %__MODULE__{
          id: Uniq.UUID.formatted(),
          user_id: Uniq.UUID.formatted(),
          category_id: Uniq.UUID.formatted() | nil,
          name: String.t(),
          value_in_cents: integer(),
          day_of_month: integer(),
          type: TransactionType.t(),
          active: boolean(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t() | nil
        }

  schema "fixed_transactions" do
    field :name, :string
    field :value_in_cents, :integer
    field :day_of_month, :integer
    field :type, Ecto.Enum, values: TransactionType.all()
    field :active, :boolean, default: true

    belongs_to :user, User
    belongs_to :category, Category

    timestamps(type: :utc_datetime_usec)
  end

  @spec changeset(%__MODULE__{} | t(), map()) :: Ecto.Changeset.t()
  def changeset(schema \\ %__MODULE__{}, params),
    do:
      schema
      |> cast(params, @required_params ++ @optional_params)
      |> validate_required(@required_params)
      |> validate_length(:name, max: 255)
      |> validate_number(:value_in_cents, greater_than: 0)
      |> validate_inclusion(:day_of_month, 1..28)
      |> assoc_constraint(:user)
      |> assoc_constraint(:category)
end
