defmodule Core.User.Services.UpdateUserService do
  @moduledoc """
  Service for updating an existing user.

  Accepts the user's ID and a map of attributes to update. Returns
  `{:error, :not_found}` if no user exists with the given ID.
  """

  alias Core.Repo
  alias Core.Schemas.User

  @spec execute(String.t(), map()) ::
          {:ok, User.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def execute(id, params) do
    with {:ok, user} <- get_user(id),
         do:
           user
           |> User.changeset(params)
           |> Repo.update()
  end

  defp get_user(id) do
    case Repo.get(User, id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end
end
