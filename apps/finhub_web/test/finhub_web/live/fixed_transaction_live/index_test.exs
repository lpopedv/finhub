defmodule FinhubWeb.FixedTransactionLive.IndexTest do
  use FinhubWeb.ConnCase, async: true

  import Core.Factory
  import Phoenix.LiveViewTest

  describe "authentication" do
    test "redirects to sign-in when unauthenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/fixed-transactions")
    end
  end

  describe "listing" do
    setup %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{"user_id" => user.id})
      {:ok, conn: conn, user: user}
    end

    test "renders title and create button", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/fixed-transactions")

      assert html =~ "Transações Fixas"
      assert html =~ "Nova Transação Fixa"
    end

    test "displays user's fixed transactions", %{conn: conn, user: user} do
      insert(:fixed_transaction,
        user: user,
        name: "Netflix",
        value_in_cents: 4_590,
        day_of_month: 15
      )

      {:ok, _view, html} = live(conn, ~p"/fixed-transactions")

      assert html =~ "Netflix"
      assert html =~ "4590"
      assert html =~ "15"
    end

    test "does not display other user's fixed transactions", %{conn: conn} do
      other_user = insert(:user)
      insert(:fixed_transaction, user: other_user, name: "Privada")

      {:ok, _view, html} = live(conn, ~p"/fixed-transactions")

      refute html =~ "Privada"
    end
  end

  describe "creation modal" do
    setup %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{"user_id" => user.id})
      {:ok, conn: conn, user: user}
    end

    test "opens modal on Nova Transação Fixa click", %{conn: conn} do
      {:ok, view, initial_html} = live(conn, ~p"/fixed-transactions")
      refute initial_html =~ "modal-open"

      html =
        view
        |> element("button", "Nova Transação Fixa")
        |> render_click()

      assert html =~ "modal-open"
      assert html =~ "Nova Transação Fixa"
    end

    test "closes modal on Cancelar click", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/fixed-transactions")

      view
      |> element("button", "Nova Transação Fixa")
      |> render_click()

      html =
        view
        |> element("button", "Cancelar")
        |> render_click()

      refute html =~ "modal-open"
    end

    test "shows validation error when name is blank", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/fixed-transactions")

      view
      |> element("button", "Nova Transação Fixa")
      |> render_click()

      html =
        view
        |> form("form", %{
          "fixed_transaction" => %{
            "name" => "",
            "value_in_cents" => "1000",
            "day_of_month" => "5"
          }
        })
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "shows validation error when day_of_month is blank", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/fixed-transactions")

      view
      |> element("button", "Nova Transação Fixa")
      |> render_click()

      html =
        view
        |> form("form", %{
          "fixed_transaction" => %{
            "name" => "Netflix",
            "value_in_cents" => "4590",
            "day_of_month" => ""
          }
        })
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "creates successfully, shows flash and closes modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/fixed-transactions")

      view
      |> element("button", "Nova Transação Fixa")
      |> render_click()

      view
      |> form("form", %{
        "fixed_transaction" => %{
          "name" => "Netflix",
          "value_in_cents" => "4590",
          "day_of_month" => "15",
          "type" => "expense"
        }
      })
      |> render_submit()

      html = render(view)

      assert html =~ "Netflix"
      assert html =~ "4590"
      assert html =~ "Transação fixa criada com sucesso!"
      refute html =~ "modal-open"
    end

    test "creates with category", %{conn: conn, user: user} do
      category = insert(:category, user: user, name: "Entretenimento")

      {:ok, view, _html} = live(conn, ~p"/fixed-transactions")

      view
      |> element("button", "Nova Transação Fixa")
      |> render_click()

      view
      |> form("form", %{
        "fixed_transaction" => %{
          "name" => "Netflix",
          "value_in_cents" => "4590",
          "day_of_month" => "15",
          "category_id" => category.id,
          "type" => "expense"
        }
      })
      |> render_submit()

      assert render(view) =~ "Transação fixa criada com sucesso!"
    end
  end

  describe "edit modal" do
    setup %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{"user_id" => user.id})
      {:ok, conn: conn, user: user}
    end

    test "opens edit modal with existing data", %{conn: conn, user: user} do
      insert(:fixed_transaction,
        user: user,
        name: "Netflix",
        value_in_cents: 4_590,
        day_of_month: 15
      )

      {:ok, view, _html} = live(conn, ~p"/fixed-transactions")

      html =
        view
        |> element("button", "Editar")
        |> render_click()

      assert html =~ "modal-open"
      assert html =~ "Editar Transação Fixa"
      assert html =~ "Netflix"
    end

    test "updates successfully, shows flash and closes modal", %{conn: conn, user: user} do
      insert(:fixed_transaction,
        user: user,
        name: "Netflix",
        value_in_cents: 4_590,
        day_of_month: 15
      )

      {:ok, view, _html} = live(conn, ~p"/fixed-transactions")

      view
      |> element("button", "Editar")
      |> render_click()

      view
      |> form("form", %{
        "fixed_transaction" => %{"name" => "Netflix Premium", "value_in_cents" => "5590"}
      })
      |> render_submit()

      html = render(view)

      assert html =~ "Netflix Premium"
      assert html =~ "5590"
      assert html =~ "Transação fixa atualizada com sucesso!"
      refute html =~ "modal-open"
    end

    test "shows validation error when trying to save blank name", %{conn: conn, user: user} do
      insert(:fixed_transaction, user: user, name: "Netflix")

      {:ok, view, _html} = live(conn, ~p"/fixed-transactions")

      view
      |> element("button", "Editar")
      |> render_click()

      html =
        view
        |> form("form", %{"fixed_transaction" => %{"name" => ""}})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
      assert html =~ "modal-open"
    end

    test "does not open modal for another user's fixed transaction", %{conn: conn} do
      other_user = insert(:user)
      other_ft = insert(:fixed_transaction, user: other_user, name: "Privada")

      {:ok, view, _html} = live(conn, ~p"/fixed-transactions")

      html = render_click(view, "edit_fixed_transaction", %{"id" => other_ft.id})

      refute html =~ "modal-open"
    end
  end

  describe "deletion" do
    setup %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{"user_id" => user.id})
      {:ok, conn: conn, user: user}
    end

    test "deletes successfully and shows flash", %{conn: conn, user: user} do
      insert(:fixed_transaction, user: user, name: "Netflix")

      {:ok, view, _html} = live(conn, ~p"/fixed-transactions")

      html =
        view
        |> element("button", "Excluir")
        |> render_click()

      refute html =~ "Netflix"
      assert html =~ "Transação fixa excluída com sucesso!"
    end

    test "does not delete another user's fixed transaction", %{conn: conn} do
      other_user = insert(:user)
      other_ft = insert(:fixed_transaction, user: other_user, name: "Privada")

      {:ok, view, _html} = live(conn, ~p"/fixed-transactions")

      html = render_click(view, "delete_fixed_transaction", %{"id" => other_ft.id})

      assert html =~ "Transação fixa não encontrada."
    end
  end
end
