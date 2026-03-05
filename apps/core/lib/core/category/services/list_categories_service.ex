defmodule Core.Category.Services.ListCategoriesService do
  @moduledoc """
  Service for listing categories of a user.

  Returns categories ordered by insertion date, most recent first.
  """

  import Ecto.Query

  alias Core.Repo
  alias Core.Schemas.Category

  @spec execute(String.t()) :: {:ok, [Category.t()]}
  def execute(user_id) do
    queryable =
      from(c in Category,
        where: c.user_id == ^user_id,
        order_by: [desc: c.inserted_at]
      )

    Repo.all(queryable)
  end
end
