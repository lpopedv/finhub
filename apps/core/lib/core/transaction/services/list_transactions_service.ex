defmodule Core.Transaction.Services.ListTransactionsService do
  @moduledoc """
  Service for listing transactions of a user.

  Returns transactions ordered by transaction date, most recent first.
  Category is preloaded. The `search` filter matches against transaction name
  and category name (case-insensitive substring match).
  """

  import Ecto.Query

  alias Core.Repo
  alias Core.Schemas.Category
  alias Core.Schemas.Transaction
  alias Core.Transaction.Commands.ListTransactionsCommand

  @spec execute(ListTransactionsCommand.t()) :: [Transaction.t()]
  def execute(%ListTransactionsCommand{user_id: user_id, search: search}) do
    queryable =
      from(t in Transaction,
        left_join: c in Category,
        on: t.category_id == c.id,
        where: t.user_id == ^user_id,
        order_by: [desc: t.date, desc: t.inserted_at],
        preload: [:category]
      )

    queryable
    |> maybe_filter_search(search)
    |> Repo.all()
  end

  defp maybe_filter_search(queryable, nil), do: queryable
  defp maybe_filter_search(queryable, ""), do: queryable

  defp maybe_filter_search(queryable, search),
    do:
      where(
        queryable,
        [t, c],
        ilike(t.name, ^"%#{search}%") or ilike(c.name, ^"%#{search}%")
      )
end
