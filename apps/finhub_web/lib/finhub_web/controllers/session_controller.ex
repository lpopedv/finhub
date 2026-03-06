defmodule FinhubWeb.SessionController do
  @moduledoc """
  Handles session creation and deletion.
  """

  use FinhubWeb, :controller

  alias Core.Auth.Commands.AuthenticateUserCommand
  alias Core.Auth.Services.AuthenticateUserService

  @spec sign_in_form(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def sign_in_form(conn, _params) do
    render(conn, :sign_in_form)
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"email" => email, "password" => password}) do
    with {:ok, command} <- AuthenticateUserCommand.build(%{email: email, password: password}),
         {:ok, user} <- AuthenticateUserService.execute(command) do
      conn
      |> put_session("user_id", user.id)
      |> put_session("live_socket_id", "users_socket:#{user.id}")
      |> configure_session(renew: true)
      |> redirect(to: ~p"/")
    else
      _error ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> render(:sign_in_form)
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, _params) do
    user_id = get_session(conn, "user_id")
    FinhubWeb.Endpoint.broadcast("users_socket:#{user_id}", "disconnect", %{})

    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/sign-in")
  end
end
