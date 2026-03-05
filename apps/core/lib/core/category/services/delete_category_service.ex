defmodule Core.Category.Services.DeleteCategoryService do
  @moduledoc """
  Service for deleting a category by ID.

  Returns `{:error, :not_found}` if no category exists with the given ID.
  """

  alias Core.Repo
  alias Core.Schemas.Category

  @spec execute(String.t()) :: {:ok, Category.t()} | {:error, :not_found}
  def execute(id) do
    with {:ok, category} <- get_category(id), do: Repo.delete(category)
  end

  defp get_category(id) do
    case Repo.get(Category, id) do
      nil -> {:error, :not_found}
      category -> {:ok, category}
    end
  end
end
