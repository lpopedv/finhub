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
      <.header>Projeções</.header>

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

      <div :if={@projections == []} class="alert mt-6">
        Nenhuma projeção encontrada.
      </div>

      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 mt-6">
        <div :for={entry <- @projections} class="stats shadow w-full">
          <div class="stat">
            <div class="stat-title">{month_name(entry.month)}</div>
            <div class="stat-value">{format_brl(entry.projected_in_cents)}</div>
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
