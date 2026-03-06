defmodule FinhubWeb.Live.Hooks.UserAuthTest do
  use FinhubWeb.ConnCase, async: true

  import Core.Factory
  import Phoenix.LiveViewTest

  describe "on_mount :default" do
    test "redirects to sign-in when session has no user_id", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/")
    end

    test "redirects to sign-in when user_id does not exist in the database", %{conn: conn} do
      conn = init_test_session(conn, %{"user_id" => Uniq.UUID.uuid7()})

      assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/")
    end

    test "mounts successfully and assigns current_user when session is valid", %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{"user_id" => user.id})

      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "Dashboard"
    end
  end
end
