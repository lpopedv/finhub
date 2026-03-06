defmodule FinhubWeb.Live.Hooks.UserAuth do
  @moduledoc """
  LiveView mount hook that validates authentication via session.

  Protects LiveView routes on WebSocket reconnections where plugs do not run.
  Assigns :current_user to the socket if the session is valid.
  """

  import Phoenix.LiveView

  alias Core.Repo
  alias Core.Schemas.User

  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()} | {:halt, Phoenix.LiveView.Socket.t()}
  def on_mount(:default, _params, session, socket) do
    socket =
      Phoenix.Component.assign_new(socket, :current_user, fn ->
        user_id = Map.get(session, "user_id")
        user_id && Repo.get(User, user_id)
      end)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/sign-in")}
    end
  end
end
