defmodule FinhubWeb.Plugs.RequireAuthPlug do
  @moduledoc """
  Plug that requires a valid session to access a route.

  Redirects unauthenticated requests to the sign-in page.
  """

  import Plug.Conn
  import Phoenix.Controller

  @spec init(keyword()) :: keyword()
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), keyword()) :: Plug.Conn.t()
  def call(conn, _opts) do
    if get_session(conn, "user_id") do
      conn
    else
      conn
      |> redirect(to: "/sign-in")
      |> halt()
    end
  end
end
