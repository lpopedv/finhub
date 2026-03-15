defmodule FinhubWeb.TransactionLive.IndexTest do
  use FinhubWeb.ConnCase, async: true

  import Core.Factory
  import Phoenix.LiveViewTest

  describe "authentication" do
    test "redirects to sign-in when unauthenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/transactions")
    end
  end

  describe "transaction listing" do
    setup %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{"user_id" => user.id})
      {:ok, conn: conn, user: user}
    end

    test "renders title and create button", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/transactions")
      assert html =~ "Transações"
      assert html =~ "Nova Transação"
    end

    test "displays authenticated user's transactions", %{conn: conn, user: user} do
      insert(:transaction, user: user, name: "Aluguel", value_in_cents: 150_000)
      insert(:transaction, user: user, name: "Internet", value_in_cents: 10_000)

      {:ok, _view, html} = live(conn, ~p"/transactions")

      assert html =~ "Aluguel"
      assert html =~ "R$ 1500,00"
      assert html =~ "Internet"
      assert html =~ "R$ 100,00"
    end

    test "does not display other user's transactions", %{conn: conn} do
      outro_user = insert(:user)
      insert(:transaction, user: outro_user, name: "Transação Alheia")

      {:ok, _view, html} = live(conn, ~p"/transactions")

      refute html =~ "Transação Alheia"
    end

    test "renders empty table when user has no transactions", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/transactions")

      assert html =~ "Transações"
    end
  end

  describe "creation modal" do
    setup %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{"user_id" => user.id})
      {:ok, conn: conn, user: user}
    end

    test "opens modal on Nova Transação click", %{conn: conn} do
      {:ok, view, initial_html} = live(conn, ~p"/transactions")
      refute initial_html =~ "modal-open"

      html =
        view
        |> element("button", "Nova Transação")
        |> render_click()

      assert html =~ "modal-open"
      assert html =~ "Nova Transação"
    end

    test "closes modal on Cancelar click", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/transactions")

      view
      |> element("button", "Nova Transação")
      |> render_click()

      html =
        view
        |> element("button", "Cancelar")
        |> render_click()

      refute html =~ "modal-open"
    end

    test "shows validation error when name is blank", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/transactions")

      view
      |> element("button", "Nova Transação")
      |> render_click()

      html =
        view
        |> form("form[phx-submit='save']", %{
          "transaction" => %{"name" => "", "value_in_cents" => "1000"}
        })
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "creates transaction successfully, shows flash and closes modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/transactions")

      view
      |> element("button", "Nova Transação")
      |> render_click()

      view
      |> form("form[phx-submit='save']", %{
        "transaction" => %{
          "name" => "Aluguel",
          "value_in_cents" => "150000",
          "date" => "2026-03-08",
          "type" => "expense"
        }
      })
      |> render_submit()

      html = render(view)

      assert html =~ "Aluguel"
      assert html =~ "R$ 1500,00"
      assert html =~ "Transação criada com sucesso!"
      refute html =~ "modal-open"
    end

    test "validates in real time while typing", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/transactions")

      view
      |> element("button", "Nova Transação")
      |> render_click()

      html =
        view
        |> form("form[phx-submit='save']", %{
          "transaction" => %{"name" => "", "value_in_cents" => ""}
        })
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end

    test "creates transaction with category", %{conn: conn, user: user} do
      category = insert(:category, user: user, name: "Moradia")

      {:ok, view, _html} = live(conn, ~p"/transactions")

      view
      |> element("button", "Nova Transação")
      |> render_click()

      view
      |> form("form[phx-submit='save']", %{
        "transaction" => %{
          "name" => "Aluguel",
          "value_in_cents" => "150000",
          "category_id" => category.id,
          "date" => "2026-03-08",
          "type" => "expense"
        }
      })
      |> render_submit()

      assert render(view) =~ "Transação criada com sucesso!"
    end

    test "creates transaction without category (prompt vazio)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/transactions")

      view
      |> element("button", "Nova Transação")
      |> render_click()

      view
      |> form("form[phx-submit='save']", %{
        "transaction" => %{
          "name" => "Salário",
          "value_in_cents" => "500000",
          "category_id" => "",
          "date" => "2026-03-08",
          "type" => "income"
        }
      })
      |> render_submit()

      assert render(view) =~ "Transação criada com sucesso!"
    end
  end

  describe "edit modal" do
    setup %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{"user_id" => user.id})
      {:ok, conn: conn, user: user}
    end

    test "opens edit modal with existing data", %{conn: conn, user: user} do
      insert(:transaction, user: user, name: "Aluguel", value_in_cents: 150_000)

      {:ok, view, _html} = live(conn, ~p"/transactions")

      html =
        view
        |> element("button", "Editar")
        |> render_click()

      assert html =~ "modal-open"
      assert html =~ "Editar Transação"
      assert html =~ "Aluguel"
    end

    test "updates transaction successfully, shows flash and closes modal", %{
      conn: conn,
      user: user
    } do
      insert(:transaction, user: user, name: "Aluguel", value_in_cents: 150_000)

      {:ok, view, _html} = live(conn, ~p"/transactions")

      view
      |> element("button", "Editar")
      |> render_click()

      view
      |> form("form[phx-submit='save']", %{
        "transaction" => %{"name" => "Aluguel Novo", "value_in_cents" => "200000"}
      })
      |> render_submit()

      html = render(view)

      assert html =~ "Aluguel Novo"
      assert html =~ "R$ 2000,00"
      assert html =~ "Transação atualizada com sucesso!"
      refute html =~ "modal-open"
    end

    test "shows validation error when trying to save blank name", %{conn: conn, user: user} do
      insert(:transaction, user: user, name: "Aluguel", value_in_cents: 150_000)

      {:ok, view, _html} = live(conn, ~p"/transactions")

      view
      |> element("button", "Editar")
      |> render_click()

      html =
        view
        |> form("form[phx-submit='save']", %{"transaction" => %{"name" => ""}})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
      assert html =~ "modal-open"
    end

    test "does not open modal for another user's transaction", %{conn: conn} do
      outro_user = insert(:user)
      outra_transacao = insert(:transaction, user: outro_user, name: "Privada")

      {:ok, view, _html} = live(conn, ~p"/transactions")

      html = render_click(view, "edit_transaction", %{"id" => outra_transacao.id})

      refute html =~ "modal-open"
    end
  end

  describe "transaction deletion" do
    setup %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{"user_id" => user.id})
      {:ok, conn: conn, user: user}
    end

    test "shows delete button for each transaction", %{conn: conn, user: user} do
      insert(:transaction, user: user, name: "Aluguel")

      {:ok, _view, html} = live(conn, ~p"/transactions")

      assert html =~ "Excluir"
    end

    test "deletes transaction successfully and shows flash", %{conn: conn, user: user} do
      insert(:transaction, user: user, name: "Aluguel")

      {:ok, view, _html} = live(conn, ~p"/transactions")

      html =
        view
        |> element("button", "Excluir")
        |> render_click()

      refute html =~ "Aluguel"
      assert html =~ "Transação excluída com sucesso!"
    end

    test "does not delete another user's transaction", %{conn: conn} do
      outro_user = insert(:user)
      outra_transacao = insert(:transaction, user: outro_user, name: "Privada")

      {:ok, view, _html} = live(conn, ~p"/transactions")

      html = render_click(view, "delete_transaction", %{"id" => outra_transacao.id})

      assert html =~ "Transação não encontrada."
    end
  end
end
