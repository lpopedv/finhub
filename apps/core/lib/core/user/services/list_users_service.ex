defmodule Core.User.Services.ListUsersService do
  @moduledoc """
  Service for listing all users.

  Returns users ordered by insertion date, most recent first.
  """

  import Ecto.Query

  alias Core.Repo
  alias Core.Schemas.User

  @spec execute() :: {:ok, [User.t()]}
  def execute do
    queryable =
      from(u in User,
        order_by: [desc: u.inserted_at]
      )

    Repo.all(queryable)
  end
end
