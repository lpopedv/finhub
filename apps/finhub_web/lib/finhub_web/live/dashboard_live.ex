defmodule FinhubWeb.DashboardLive do
  use FinhubWeb, :live_view

  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Dashboard")}
  end

  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <Layouts.app>
      <.header>Dashboard</.header>
    </Layouts.app>
    """
  end
end
