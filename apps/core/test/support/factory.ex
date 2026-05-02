defmodule Core.Factory do
  use ExMachina.Ecto, repo: Core.Repo

  alias Core.Schemas.AiAgent
  alias Core.Schemas.AiAgentPrompt
  alias Core.Schemas.Category
  alias Core.Schemas.Conversation
  alias Core.Schemas.FixedTransaction
  alias Core.Schemas.Transaction
  alias Core.Schemas.User

  def ai_agent_factory do
    %AiAgent{
      user: build(:user),
      name: sequence(:ai_agent_name, &"AI Agent #{&1}"),
      description: nil
    }
  end

  def conversation_factory do
    %Conversation{
      user: build(:user),
      ai_agent: nil,
      title: nil,
      active: true
    }
  end

  def ai_agent_prompt_factory do
    %AiAgentPrompt{
      ai_agent: build(:ai_agent),
      content: "You are a helpful financial assistant.",
      version: 1,
      active: false
    }
  end

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
      day_of_month: 5,
      type: :expense
    }
  end

  def transaction_factory do
    %Transaction{
      user: build(:user),
      category: nil,
      name: sequence(:name, &"Transaction #{&1}"),
      value_in_cents: 1000,
      date: Date.utc_today(),
      type: :expense
    }
  end
end
