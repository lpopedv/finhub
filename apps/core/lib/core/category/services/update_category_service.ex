defmodule Core.Category.Services.UpdateCategoryService do
  @moduledoc """
  Service for updating an existing category.

  Accepts the category's ID and a map of attributes to update. Returns
  `{:error, :not_found}` if no category exists with the given ID.
  """

  alias Core.Repo
  alias Core.Schemas.Category

  @spec execute(String.t(), map()) ::
          {:ok, Category.t()} | {:error, :not_found} | {:error, Ecto.Changeset.t()}
  def execute(id, params) do
    with {:ok, category} <- get_category(id),
         do:
           category
           |> Category.changeset(params)
           |> Repo.update()
  end

  defp get_category(id) do
    case Repo.get(Category, id) do
      nil -> {:error, :not_found}
      category -> {:ok, category}
    end
  end
end
