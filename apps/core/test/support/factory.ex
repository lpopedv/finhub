defmodule Core.Factory do
  use ExMachina.Ecto, repo: Core.Repo

  alias Core.Schemas.Category
  alias Core.Schemas.FixedTransaction
  alias Core.Schemas.Transaction
  alias Core.Schemas.User

  def user_factory do
    %User{
      full_name: "John Doe",
      email: sequence(:email, &"user-#{&1}@example.com"),
      password_hash: Argon2.hash_pwd_salt("password123")
    }
  end

  def category_factory do
    %Category{
      user: build(:user),
      name: sequence(:name, &"Category #{&1}"),
      description: nil
    }
  end

  def fixed_transaction_factory do
    %FixedTransaction{
      user: build(:user),
      category: nil,
      name: sequence(:name, &"Fixed Transaction #{&1}"),
      value_in_cents: 1000,
      day_of_month: 5
    }
  end

  def transaction_factory do
    %Transaction{
      user: build(:user),
      category: nil,
      name: sequence(:name, &"Transaction #{&1}"),
      value_in_cents: 1000,
      date: Date.utc_today()
    }
  end
end
