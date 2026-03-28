defmodule FinhubWeb.DashboardLive do
  use FinhubWeb, :live_view

  alias Core.Dashboard.Services.GetDashboardSummaryService

  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    summary = GetDashboardSummaryService.execute(user_id)

    {:ok,
     socket
     |> assign(page_title: "Dashboard")
     |> assign(summary: summary)}
  end

  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>Dashboard</.header>

      <div class="stats stats-vertical sm:stats-horizontal shadow mt-8 w-full">
        <div class="stat">
          <div class="stat-title">Gastos fixos mensais</div>
          <div class="stat-value">{format_brl(@summary.fixed_expenses_total)}</div>
          <div class="stat-desc">Recorrências ativas</div>
        </div>

        <div class="stat">
          <div class="stat-title">Projeção do próximo mês</div>
          <div class="stat-value">{format_brl(@summary.next_month_expenses_total)}</div>
          <div class="stat-desc">Fixos + despesas variáveis já lançadas</div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
