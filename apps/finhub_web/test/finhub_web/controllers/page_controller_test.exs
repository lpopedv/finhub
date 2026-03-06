defmodule FinhubWeb.DashboardLiveTest do
  use FinhubWeb.ConnCase, async: true

  import Core.Factory
  import Phoenix.LiveViewTest

  test "GET / redirects to sign-in when not authenticated", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/")
  end

  test "GET / renders dashboard when authenticated", %{conn: conn} do
    user = insert(:user)
    conn = init_test_session(conn, %{"user_id" => user.id})

    {:ok, _view, html} = live(conn, ~p"/")

    assert html =~ "Dashboard"
  end
end
