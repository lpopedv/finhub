defmodule FinhubWeb.MonthlyReportLiveTest do
  use FinhubWeb.ConnCase, async: true

  import Core.Factory
  import Phoenix.LiveViewTest

  describe "authentication" do
    test "redirects to sign-in when unauthenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/monthly-report")
    end
  end

  describe "monthly report" do
    setup %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{"user_id" => user.id})
      {:ok, conn: conn, user: user}
    end

    test "renders title and filter buttons", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/monthly-report")

      assert html =~ "Resumo Mensal"
      assert html =~ "Todos"
      assert html =~ "Despesas"
      assert html =~ "Receitas"
    end

    test "shows empty state when user has no transactions", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/monthly-report")

      assert html =~ "Nenhuma transação encontrada."
    end

    test "displays stat cards for months with transactions", %{conn: conn, user: user} do
      today = Date.utc_today()
      insert(:transaction, user: user, value_in_cents: 50_000, date: today, type: :expense)

      {:ok, _view, html} = live(conn, ~p"/monthly-report")

      refute html =~ "Nenhuma transação encontrada."
      assert html =~ "R$ 500,00"
    end

    test "does not display other user's transactions", %{conn: conn} do
      other_user = insert(:user)
      insert(:transaction, user: other_user, value_in_cents: 99_900, date: Date.utc_today())

      {:ok, _view, html} = live(conn, ~p"/monthly-report")

      assert html =~ "Nenhuma transação encontrada."
    end

    test "filter by expense shows only expense totals", %{conn: conn, user: user} do
      today = Date.utc_today()
      insert(:transaction, user: user, value_in_cents: 30_000, date: today, type: :expense)
      insert(:transaction, user: user, value_in_cents: 100_000, date: today, type: :income)

      {:ok, view, _html} = live(conn, ~p"/monthly-report")

      html =
        view
        |> element("button", "Despesas")
        |> render_click()

      assert html =~ "R$ 300,00"
      refute html =~ "R$ 1000,00"
    end

    test "filter by income shows only income totals", %{conn: conn, user: user} do
      today = Date.utc_today()
      insert(:transaction, user: user, value_in_cents: 30_000, date: today, type: :expense)
      insert(:transaction, user: user, value_in_cents: 100_000, date: today, type: :income)

      {:ok, view, _html} = live(conn, ~p"/monthly-report")

      html =
        view
        |> element("button", "Receitas")
        |> render_click()

      assert html =~ "R$ 1000,00"
      refute html =~ "R$ 300,00"
    end

    test "filter todos shows all transactions after filtering", %{conn: conn, user: user} do
      today = Date.utc_today()
      insert(:transaction, user: user, value_in_cents: 30_000, date: today, type: :expense)
      insert(:transaction, user: user, value_in_cents: 100_000, date: today, type: :income)

      {:ok, view, _html} = live(conn, ~p"/monthly-report")

      view
      |> element("button", "Despesas")
      |> render_click()

      html =
        view
        |> element("button", "Todos")
        |> render_click()

      assert html =~ "R$ 1300,00"
    end

    test "shows empty state when filter has no matching transactions", %{conn: conn, user: user} do
      today = Date.utc_today()
      insert(:transaction, user: user, value_in_cents: 50_000, date: today, type: :expense)

      {:ok, view, _html} = live(conn, ~p"/monthly-report")

      html =
        view
        |> element("button", "Receitas")
        |> render_click()

      assert html =~ "Nenhuma transação encontrada."
    end
  end
end
