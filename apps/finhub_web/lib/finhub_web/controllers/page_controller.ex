defmodule FinhubWeb.PageController do
  use FinhubWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
