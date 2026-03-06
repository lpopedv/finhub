defmodule FinhubWeb.PageControllerTest do
  use FinhubWeb.ConnCase, async: true

  test "GET / redirects to sign-in when not authenticated", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/sign-in"
  end

  test "GET / renders when authenticated", %{conn: conn} do
    conn =
      conn
      |> Plug.Test.init_test_session(%{"user_id" => "some-user-id"})
      |> get(~p"/")

    assert html_response(conn, 200) =~ "Peace of mind from prototype to production"
  end
end
