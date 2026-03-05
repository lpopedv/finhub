defmodule Core.Category.Services.CreateCategoryService do
  @moduledoc """
  Service for creating categories.

  This service handles the creation of a new category by taking a validated
  `CreateCategoryCommand` and persisting it to the database as a `Category` schema.
  """

  alias Core.Category.Commands.CreateCategoryCommand
  alias Core.Repo
  alias Core.Schemas.Category

  @spec execute(CreateCategoryCommand.t()) :: {:ok, Category.t()} | {:error, Ecto.Changeset.t()}
  def execute(%CreateCategoryCommand{} = command),
    do:
      %{
        user_id: command.user_id,
        name: command.name,
        description: command.description
      }
      |> Category.changeset()
      |> Repo.insert()
end
