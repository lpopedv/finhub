defmodule FinhubWeb.CategoryLive.IndexTest do
  use FinhubWeb.ConnCase, async: true

  import Core.Factory
  import Phoenix.LiveViewTest

  describe "authentication" do
    test "redirects to sign-in when unauthenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/categories")
    end
  end

  describe "category listing" do
    setup %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{"user_id" => user.id})
      {:ok, conn: conn, user: user}
    end

    test "renders title and create button", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/categories")
      assert html =~ "Categorias"
      assert html =~ "Nova Categoria"
    end

    test "displays authenticated user's categories", %{conn: conn, user: user} do
      insert(:category, user: user, name: "Alimentação", description: "Gastos com comida")
      insert(:category, user: user, name: "Transporte", description: nil)

      {:ok, _view, html} = live(conn, ~p"/categories")

      assert html =~ "Alimentação"
      assert html =~ "Gastos com comida"
      assert html =~ "Transporte"
    end

    test "does not display other user's categories", %{conn: conn} do
      outro_user = insert(:user)
      insert(:category, user: outro_user, name: "Categoria Alheia")

      {:ok, _view, html} = live(conn, ~p"/categories")

      refute html =~ "Categoria Alheia"
    end

    test "renders empty table when user has no categories", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/categories")

      assert html =~ "Categorias"
      refute html =~ "Category"
    end
  end

  describe "creation modal" do
    setup %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{"user_id" => user.id})
      {:ok, conn: conn, user: user}
    end

    test "opens modal on Nova Categoria click", %{conn: conn} do
      {:ok, view, initial_html} = live(conn, ~p"/categories")
      refute initial_html =~ "modal-open"

      html =
        view
        |> element("button", "Nova Categoria")
        |> render_click()

      assert html =~ "modal-open"
      assert html =~ "Nova Categoria"
    end

    test "closes modal on Cancelar click", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/categories")

      view
      |> element("button", "Nova Categoria")
      |> render_click()

      html =
        view
        |> element("button", "Cancelar")
        |> render_click()

      refute html =~ "modal-open"
    end

    test "shows validation error when name is blank", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/categories")

      view
      |> element("button", "Nova Categoria")
      |> render_click()

      html =
        view
        |> form("form", %{"category" => %{"name" => "", "description" => ""}})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "creates category successfully, shows flash and closes modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/categories")

      view
      |> element("button", "Nova Categoria")
      |> render_click()

      view
      |> form("form", %{"category" => %{"name" => "Lazer", "description" => "Diversão"}})
      |> render_submit()

      html = render(view)

      assert html =~ "Lazer"
      assert html =~ "Diversão"
      assert html =~ "Categoria criada com sucesso!"
      refute html =~ "modal-open"
    end

    test "shows error when name already exists for user", %{conn: conn, user: user} do
      insert(:category, user: user, name: "Existente")

      {:ok, view, _html} = live(conn, ~p"/categories")

      view
      |> element("button", "Nova Categoria")
      |> render_click()

      html =
        view
        |> form("form", %{"category" => %{"name" => "Existente"}})
        |> render_submit()

      assert html =~ "has already been taken"
      assert html =~ "modal-open"
    end

    test "validates in real time while typing", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/categories")

      view
      |> element("button", "Nova Categoria")
      |> render_click()

      html =
        view
        |> form("form", %{"category" => %{"name" => ""}})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "edit modal" do
    setup %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{"user_id" => user.id})
      {:ok, conn: conn, user: user}
    end

    test "opens edit modal with existing data", %{conn: conn, user: user} do
      insert(:category, user: user, name: "Alimentação", description: "Gastos com comida")

      {:ok, view, _html} = live(conn, ~p"/categories")

      html =
        view
        |> element("button", "Editar")
        |> render_click()

      assert html =~ "modal-open"
      assert html =~ "Editar Categoria"
      assert html =~ "Alimentação"
    end

    test "updates category successfully, shows flash and closes modal", %{conn: conn, user: user} do
      insert(:category, user: user, name: "Alimentação", description: "Gastos com comida")

      {:ok, view, _html} = live(conn, ~p"/categories")

      view
      |> element("button", "Editar")
      |> render_click()

      view
      |> form("form", %{
        "category" => %{"name" => "Alimentação Saudável", "description" => "Novo texto"}
      })
      |> render_submit()

      html = render(view)

      assert html =~ "Alimentação Saudável"
      assert html =~ "Novo texto"
      assert html =~ "Categoria atualizada com sucesso!"
      refute html =~ "modal-open"
    end

    test "shows validation error when trying to save blank name", %{conn: conn, user: user} do
      insert(:category, user: user, name: "Alimentação")

      {:ok, view, _html} = live(conn, ~p"/categories")

      view
      |> element("button", "Editar")
      |> render_click()

      html =
        view
        |> form("form", %{"category" => %{"name" => ""}})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
      assert html =~ "modal-open"
    end

    test "shows error when name already exists for user", %{conn: conn, user: user} do
      alimentacao = insert(:category, user: user, name: "Alimentação")
      insert(:category, user: user, name: "Transporte")

      {:ok, view, _html} = live(conn, ~p"/categories")

      render_click(view, "edit_category", %{"id" => alimentacao.id})

      html =
        view
        |> form("form", %{"category" => %{"name" => "Transporte"}})
        |> render_submit()

      assert html =~ "has already been taken"
      assert html =~ "modal-open"
    end

    test "does not open modal for another user's category", %{conn: conn} do
      outro_user = insert(:user)
      outra_categoria = insert(:category, user: outro_user, name: "Privada")

      {:ok, view, _html} = live(conn, ~p"/categories")

      html = render_click(view, "edit_category", %{"id" => outra_categoria.id})

      refute html =~ "modal-open"
    end
  end

  describe "category deletion" do
    setup %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{"user_id" => user.id})
      {:ok, conn: conn, user: user}
    end

    test "shows delete button for each category", %{conn: conn, user: user} do
      insert(:category, user: user, name: "Alimentação")

      {:ok, _view, html} = live(conn, ~p"/categories")

      assert html =~ "Excluir"
    end

    test "deletes category successfully and shows flash", %{conn: conn, user: user} do
      insert(:category, user: user, name: "Alimentação")

      {:ok, view, _html} = live(conn, ~p"/categories")

      html =
        view
        |> element("button", "Excluir")
        |> render_click()

      refute html =~ "Alimentação"
      assert html =~ "Categoria excluída com sucesso!"
    end

    test "does not delete another user's category", %{conn: conn} do
      outro_user = insert(:user)
      outra_categoria = insert(:category, user: outro_user, name: "Privada")

      {:ok, view, _html} = live(conn, ~p"/categories")

      html = render_click(view, "delete_category", %{"id" => outra_categoria.id})

      assert html =~ "Categoria não encontrada."
    end
  end
end
