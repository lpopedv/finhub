defmodule Core.Factory do
  use ExMachina.Ecto, repo: Core.Repo

  alias Core.Schemas.User

  def user_factory do
    %User{
      full_name: "John Doe",
      email: sequence(:email, &"user-#{&1}@example.com"),
      password_hash: Argon2.hash_pwd_salt("password123")
    }
  end
end
