defmodule Core.Transaction.Services.ListTransactionsService do
  @moduledoc """
  Service for listing transactions of a user.

  Returns transactions ordered by insertion date, most recent first.
  """

  import Ecto.Query

  alias Core.Repo
  alias Core.Schemas.Transaction

  @spec execute(String.t()) :: {:ok, [Transaction.t()]}
  def execute(user_id) do
    queryable =
      from(t in Transaction,
        where: t.user_id == ^user_id,
        order_by: [desc: t.inserted_at]
      )

    Repo.all(queryable)
  end
end
