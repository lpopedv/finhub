defmodule FinhubWeb.ProjectionLive do
  use FinhubWeb, :live_view

  alias Core.Projection.Commands.GetProjectionsByMonthCommand
  alias Core.Projection.Services.GetProjectionsByMonthService

  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    projections = fetch_projections(socket.assigns.current_user.id, nil)

    {:ok,
     socket
     |> assign(page_title: "Projeções")
     |> assign(projections: projections)
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
    projections = fetch_projections(socket.assigns.current_user.id, type)

    {:noreply,
     socket
     |> assign(projections: projections)
     |> assign(selected_type: selected_type)}
  end

  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="flex flex-col gap-4 pb-6 border-b border-base-300 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 class="text-2xl font-bold tracking-tight">Projeções</h1>
          <p class="mt-1 text-sm text-base-content/50">
            Próximos 12 meses com base nas transações fixas
          </p>
        </div>
        <div class="join">
          <.button
            class={["btn btn-sm join-item", @selected_type == :all && "btn-active"]}
            phx-click="filter"
            phx-value-type="all"
          >
            Todos
          </.button>
          <.button
            class={["btn btn-sm join-item", @selected_type == :expense && "btn-active"]}
            phx-click="filter"
            phx-value-type="expense"
          >
            Despesas
          </.button>
          <.button
            class={["btn btn-sm join-item", @selected_type == :income && "btn-active"]}
            phx-click="filter"
            phx-value-type="income"
          >
            Receitas
          </.button>
        </div>
      </div>

      <div
        :if={@projections == []}
        class="mt-16 flex flex-col items-center justify-center text-center"
      >
        <div class="rounded-full bg-base-200 p-6 mb-4">
          <.icon name="hero-chart-bar-square" class="size-10 text-base-content/30" />
        </div>
        <h3 class="text-lg font-semibold text-base-content/70">Nenhuma projeção disponível</h3>
        <p class="mt-1 text-sm text-base-content/40 max-w-xs">
          Cadastre transações fixas para visualizar as projeções mensais
        </p>
      </div>

      <div :if={@projections != []} class="mt-6">
        <% max_value = Enum.reduce(@projections, 0, fn e, acc -> max(e.projected_in_cents, acc) end) %>
        <% today = Date.utc_today() %>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          <div
            :for={entry <- @projections}
            class={[
              "rounded-xl border p-5 transition-colors duration-200",
              entry.month.month == today.month && entry.month.year == today.year &&
                "border-primary/40 bg-primary/5",
              !(entry.month.month == today.month && entry.month.year == today.year) &&
                "border-base-300 bg-base-200/40 hover:bg-base-200/60"
            ]}
          >
            <div class="flex items-center justify-between mb-3">
              <div class="flex items-center gap-2">
                <span class="text-xs font-semibold uppercase tracking-widest text-base-content/50">
                  {month_name(entry.month)}
                </span>
                <span class="text-xs text-base-content/30 tabular-nums">{entry.month.year}</span>
              </div>
              <span
                :if={entry.month.month == today.month && entry.month.year == today.year}
                class="badge badge-xs badge-primary"
              >
                Atual
              </span>
            </div>
            <p class={[
              "text-2xl font-bold tabular-nums",
              @selected_type == :income && "text-success",
              @selected_type == :expense && "text-error",
              @selected_type == :all && "text-base-content"
            ]}>
              {format_brl(entry.projected_in_cents)}
            </p>
            <progress
              class={[
                "progress w-full mt-3",
                @selected_type == :income && "progress-success",
                @selected_type == :expense && "progress-error",
                @selected_type == :all && "progress-primary"
              ]}
              value={entry.projected_in_cents}
              max={max(max_value, 1)}
            />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp fetch_projections(user_id, type) do
    today = Date.utc_today()
    date_start = Date.beginning_of_month(today)
    date_end = Date.end_of_month(Date.shift(today, month: 11))

    command =
      GetProjectionsByMonthCommand.build!(%{
        user_id: user_id,
        date_start: date_start,
        date_end: date_end,
        type: type
      })

    {:ok, projections} = GetProjectionsByMonthService.execute(command)
    projections
  end

  defp month_name(date) do
    ~w(Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro)
    |> Enum.at(date.month - 1)
  end
end
