defmodule Core.Schemas.Transaction do
  @moduledoc """
  Schema representing a financial transaction.

  Transactions are scoped to a user and optionally linked to a category.
  Values are stored in cents to avoid floating-point precision issues.
  When the associated category is deleted, `category_id` is set to nil.
  When the associated fixed transaction is deleted, `fixed_transaction_id` is set to nil.
  """

  use Core.Schema

  alias Core.Schemas.Category
  alias Core.Schemas.FixedTransaction
  alias Core.Schemas.User
  alias Core.TransactionType

  @required_params [:user_id, :name, :value_in_cents, :date, :type]
  @optional_params [:category_id, :fixed_transaction_id]

  @type t :: %__MODULE__{
          id: Uniq.UUID.formatted(),
          user_id: Uniq.UUID.formatted(),
          category_id: Uniq.UUID.formatted() | nil,
          fixed_transaction_id: Uniq.UUID.formatted() | nil,
          name: String.t(),
          value_in_cents: integer(),
          date: Date.t(),
          type: TransactionType.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t() | nil
        }

  schema "transactions" do
    field :name, :string
    field :value_in_cents, :integer
    field :date, :date
    field :type, Ecto.Enum, values: TransactionType.all()

    belongs_to :user, User
    belongs_to :category, Category
    belongs_to :fixed_transaction, FixedTransaction

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
      |> assoc_constraint(:user)
      |> assoc_constraint(:category)
      |> assoc_constraint(:fixed_transaction)
end
