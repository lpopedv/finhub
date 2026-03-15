defmodule FinhubWeb.MonthlyReportLive do
  use FinhubWeb, :live_view

  alias Core.Transaction.Commands.SumTransactionsByMonthCommand
  alias Core.Transaction.Services.SumTransactionsByMonthService

  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    totals = fetch_totals(socket.assigns.current_user.id, nil)

    {:ok,
     socket
     |> assign(page_title: "Resumo Mensal")
     |> assign(totals: totals)
     |> assign(selected_type: :all)}
  end

  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("filter", %{"type" => type_str}, socket) do
    type =
      case type_str do
        "expense" -> :expense
        "income" -> :income
        _other_type -> nil
      end

    selected_type = if type == nil, do: :all, else: type
    totals = fetch_totals(socket.assigns.current_user.id, type)

    {:noreply,
     socket
     |> assign(totals: totals)
     |> assign(selected_type: selected_type)}
  end

  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>Resumo Mensal</.header>

      <div class="join mt-6">
        <button
          class={"btn join-item #{if @selected_type == :all, do: "btn-active"}"}
          phx-click="filter"
          phx-value-type="all"
        >
          Todos
        </button>
        <button
          class={"btn join-item #{if @selected_type == :expense, do: "btn-active"}"}
          phx-click="filter"
          phx-value-type="expense"
        >
          Despesas
        </button>
        <button
          class={"btn join-item #{if @selected_type == :income, do: "btn-active"}"}
          phx-click="filter"
          phx-value-type="income"
        >
          Receitas
        </button>
      </div>

      <div :if={@totals == []} class="alert mt-6">
        Nenhuma transação encontrada.
      </div>

      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 mt-6">
        <div :for={entry <- @totals} class="stats shadow w-full">
          <div class="stat">
            <div class="stat-title">{month_name(entry.month)}</div>
            <div class="stat-value">{format_brl(entry.total_in_cents)}</div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp fetch_totals(user_id, type) do
    today = Date.utc_today()
    date_start = %Date{year: today.year, month: 1, day: 1}
    date_end = %Date{year: today.year, month: 12, day: 31}

    command =
      SumTransactionsByMonthCommand.build!(%{
        user_id: user_id,
        date_start: date_start,
        date_end: date_end,
        type: type
      })

    {:ok, totals} = SumTransactionsByMonthService.execute(command)
    totals
  end

  defp month_name(date) do
    [
      "Janeiro",
      "Fevereiro",
      "Março",
      "Abril",
      "Maio",
      "Junho",
      "Julho",
      "Agosto",
      "Setembro",
      "Outubro",
      "Novembro",
      "Dezembro"
    ]
    |> Enum.at(date.month - 1)
  end
end
