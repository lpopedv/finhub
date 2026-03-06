defmodule FinhubWeb.SessionControllerTest do
  use FinhubWeb.ConnCase, async: true

  import Core.Factory

  describe "GET /sign-in" do
    test "renders the sign-in form", %{conn: conn} do
      conn = get(conn, ~p"/sign-in")

      assert html_response(conn, 200) =~ "Sign in"
    end
  end

  describe "POST /sign-in" do
    setup do
      user = insert(:user)
      %{user: user}
    end

    test "redirects to / and sets session on valid credentials", %{conn: conn, user: user} do
      conn = post(conn, ~p"/sign-in", %{email: user.email, password: "password123"})

      assert redirected_to(conn) == ~p"/"
      assert get_session(conn, "user_id") == user.id
      assert get_session(conn, "live_socket_id") == "users_socket:#{user.id}"
    end

    test "renders form with error flash on invalid password", %{conn: conn, user: user} do
      conn = post(conn, ~p"/sign-in", %{email: user.email, password: "wrongpassword"})

      assert html_response(conn, 200) =~ "Invalid email or password"
    end

    test "renders form with error flash when user does not exist", %{conn: conn} do
      conn = post(conn, ~p"/sign-in", %{email: "ghost@example.com", password: "password123"})

      assert html_response(conn, 200) =~ "Invalid email or password"
    end
  end

  describe "DELETE /sign-out" do
    test "drops session and redirects to sign-in", %{conn: conn} do
      user = insert(:user)

      conn =
        conn
        |> init_test_session(%{"user_id" => user.id})
        |> delete(~p"/sign-out")

      assert redirected_to(conn) == ~p"/sign-in"
      assert conn.private[:plug_session_info] == :drop
    end
  end
end
