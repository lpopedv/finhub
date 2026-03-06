defmodule FinhubWeb.Plugs.RequireAuthPlugTest do
  use FinhubWeb.ConnCase, async: true

  alias FinhubWeb.Plugs.RequireAuthPlug

  describe "call/2" do
    test "halts and redirects to sign-in when session has no user_id", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{})
        |> RequireAuthPlug.call([])

      assert conn.halted
      assert redirected_to(conn) == "/sign-in"
    end

    test "passes through when session has a user_id", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{"user_id" => "some-user-id"})
        |> RequireAuthPlug.call([])

      refute conn.halted
    end
  end
end
