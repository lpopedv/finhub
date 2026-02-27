defmodule Core.User.Services.DeleteUserService do
  @moduledoc """
  Service for deleting a user by ID.

  Returns `{:error, :not_found}` if no user exists with the given ID.
  """

  alias Core.Repo
  alias Core.Schemas.User

  @spec execute(String.t()) :: {:ok, User.t()} | {:error, :not_found}
  def execute(id) do
    with {:ok, user} <- get_user(id), do: Repo.delete(user)
  end

  defp get_user(id) do
    case Repo.get(User, id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end
end
