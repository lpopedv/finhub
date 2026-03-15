defmodule FinhubWeb.ProjectionLiveTest do
  use FinhubWeb.ConnCase, async: true

  import Core.Factory
  import Phoenix.LiveViewTest

  describe "authentication" do
    test "redirects to sign-in when unauthenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/projections")
    end
  end

  describe "projections" do
    setup %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{"user_id" => user.id})
      {:ok, conn: conn, user: user}
    end

    test "renders title and filter buttons", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/projections")

      assert html =~ "Projeções"
      assert html =~ "Todos"
      assert html =~ "Despesas"
      assert html =~ "Receitas"
    end

    test "displays 12 monthly cards even with no transactions", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/projections")

      assert html =~ "R$ 0,00"
    end

    test "shows projected value including active fixed transactions", %{conn: conn, user: user} do
      insert(:fixed_transaction, user: user, value_in_cents: 50_000, active: true, type: :expense)

      {:ok, _view, html} = live(conn, ~p"/projections")

      assert html =~ "R$ 500,00"
    end

    test "includes variable transactions already entered for future months", %{
      conn: conn,
      user: user
    } do
      future_date = Date.shift(Date.utc_today(), month: 2)
      insert(:fixed_transaction, user: user, value_in_cents: 10_000, active: true, type: :expense)

      insert(:transaction,
        user: user,
        value_in_cents: 5_000,
        date: future_date,
        type: :expense,
        fixed_transaction: nil
      )

      {:ok, _view, html} = live(conn, ~p"/projections")

      assert html =~ "R$ 150,00"
    end

    test "filter by expense shows only expense projections", %{conn: conn, user: user} do
      insert(:fixed_transaction, user: user, value_in_cents: 30_000, active: true, type: :expense)
      insert(:fixed_transaction, user: user, value_in_cents: 100_000, active: true, type: :income)

      {:ok, view, _html} = live(conn, ~p"/projections")

      html =
        view
        |> element("button", "Despesas")
        |> render_click()

      assert html =~ "R$ 300,00"
      refute html =~ "R$ 1000,00"
    end

    test "filter by income shows only income projections", %{conn: conn, user: user} do
      insert(:fixed_transaction, user: user, value_in_cents: 30_000, active: true, type: :expense)
      insert(:fixed_transaction, user: user, value_in_cents: 100_000, active: true, type: :income)

      {:ok, view, _html} = live(conn, ~p"/projections")

      html =
        view
        |> element("button", "Receitas")
        |> render_click()

      assert html =~ "R$ 1000,00"
      refute html =~ "R$ 300,00"
    end

    test "does not show other user's fixed transactions", %{conn: conn} do
      other_user = insert(:user)
      insert(:fixed_transaction, user: other_user, value_in_cents: 99_900, active: true)

      {:ok, _view, html} = live(conn, ~p"/projections")

      refute html =~ "R$ 999,00"
    end
  end
end
