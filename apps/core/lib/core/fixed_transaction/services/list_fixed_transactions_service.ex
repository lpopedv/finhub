defmodule Core.FixedTransaction.Services.ListFixedTransactionsService do
  @moduledoc """
  Service for listing fixed transaction rules of a user.

  Returns fixed transactions ordered by day of month ascending.
  """

  import Ecto.Query

  alias Core.Repo
  alias Core.Schemas.FixedTransaction

  @spec execute(String.t()) :: [FixedTransaction.t()]
  def execute(user_id) do
    queryable = from(ft in FixedTransaction,
      where: ft.user_id == ^user_id,
      order_by: [asc: ft.day_of_month, desc: ft.inserted_at]
    )

     Repo.all(queryable)
  end
end
