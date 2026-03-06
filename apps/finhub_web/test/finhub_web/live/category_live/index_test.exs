defmodule FinhubWeb.CategoryLive.IndexTest do
  use FinhubWeb.ConnCase, async: true

  import Core.Factory
  import Phoenix.LiveViewTest

  describe "autenticação" do
    test "redireciona para sign-in quando não autenticado", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/sign-in"}}} = live(conn, ~p"/categorias")
    end
  end

  describe "listagem de categorias" do
    setup %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{"user_id" => user.id})
      {:ok, conn: conn, user: user}
    end

    test "renderiza o título e botão de criar", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/categorias")
      assert html =~ "Categorias"
      assert html =~ "Nova Categoria"
    end

    test "exibe categorias do usuário autenticado", %{conn: conn, user: user} do
      insert(:category, user: user, name: "Alimentação", description: "Gastos com comida")
      insert(:category, user: user, name: "Transporte", description: nil)

      {:ok, _view, html} = live(conn, ~p"/categorias")

      assert html =~ "Alimentação"
      assert html =~ "Gastos com comida"
      assert html =~ "Transporte"
    end

    test "não exibe categorias de outro usuário", %{conn: conn} do
      outro_user = insert(:user)
      insert(:category, user: outro_user, name: "Categoria Alheia")

      {:ok, _view, html} = live(conn, ~p"/categorias")

      refute html =~ "Categoria Alheia"
    end

    test "renderiza tabela vazia quando usuário não tem categorias", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/categorias")

      assert html =~ "Categorias"
      refute html =~ "Category"
    end
  end

  describe "modal de criação" do
    setup %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{"user_id" => user.id})
      {:ok, conn: conn, user: user}
    end

    test "abre modal ao clicar em Nova Categoria", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/categorias")
      refute html =~ "modal-open"

      html = view |> element("button", "Nova Categoria") |> render_click()

      assert html =~ "modal-open"
      assert html =~ "Nova Categoria"
    end

    test "fecha modal ao clicar em Cancelar", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/categorias")
      view |> element("button", "Nova Categoria") |> render_click()

      html = view |> element("button", "Cancelar") |> render_click()

      refute html =~ "modal-open"
    end

    test "exibe erro de validação quando nome está vazio", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/categorias")
      view |> element("button", "Nova Categoria") |> render_click()

      html =
        view
        |> form("form", %{"category" => %{"name" => "", "description" => ""}})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end

    test "cria categoria com sucesso, exibe flash e fecha modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/categorias")
      view |> element("button", "Nova Categoria") |> render_click()

      view
      |> form("form", %{"category" => %{"name" => "Lazer", "description" => "Diversão"}})
      |> render_submit()

      html = render(view)

      assert html =~ "Lazer"
      assert html =~ "Diversão"
      assert html =~ "Categoria criada com sucesso!"
      refute html =~ "modal-open"
    end

    test "exibe erro quando nome já existe para o usuário", %{conn: conn, user: user} do
      insert(:category, user: user, name: "Existente")

      {:ok, view, _html} = live(conn, ~p"/categorias")
      view |> element("button", "Nova Categoria") |> render_click()

      html =
        view
        |> form("form", %{"category" => %{"name" => "Existente"}})
        |> render_submit()

      assert html =~ "has already been taken"
      assert html =~ "modal-open"
    end

    test "valida em tempo real ao digitar", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/categorias")
      view |> element("button", "Nova Categoria") |> render_click()

      html =
        view
        |> form("form", %{"category" => %{"name" => ""}})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "modal de edição" do
    setup %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{"user_id" => user.id})
      {:ok, conn: conn, user: user}
    end

    test "abre modal de edição com dados existentes", %{conn: conn, user: user} do
      insert(:category, user: user, name: "Alimentação", description: "Gastos com comida")

      {:ok, view, _html} = live(conn, ~p"/categorias")

      html = view |> element("button", "Editar") |> render_click()

      assert html =~ "modal-open"
      assert html =~ "Editar Categoria"
      assert html =~ "Alimentação"
    end

    test "atualiza categoria com sucesso, exibe flash e fecha modal", %{conn: conn, user: user} do
      insert(:category, user: user, name: "Alimentação", description: "Gastos com comida")

      {:ok, view, _html} = live(conn, ~p"/categorias")
      view |> element("button", "Editar") |> render_click()

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

    test "exibe erro de validação ao tentar salvar nome vazio", %{conn: conn, user: user} do
      insert(:category, user: user, name: "Alimentação")

      {:ok, view, _html} = live(conn, ~p"/categorias")
      view |> element("button", "Editar") |> render_click()

      html =
        view
        |> form("form", %{"category" => %{"name" => ""}})
        |> render_submit()

      assert html =~ "can&#39;t be blank"
      assert html =~ "modal-open"
    end

    test "exibe erro quando nome já existe para o usuário", %{conn: conn, user: user} do
      alimentacao = insert(:category, user: user, name: "Alimentação")
      insert(:category, user: user, name: "Transporte")

      {:ok, view, _html} = live(conn, ~p"/categorias")

      render_click(view, "edit_category", %{"id" => alimentacao.id})

      html =
        view
        |> form("form", %{"category" => %{"name" => "Transporte"}})
        |> render_submit()

      assert html =~ "has already been taken"
      assert html =~ "modal-open"
    end

    test "não abre modal para categoria de outro usuário", %{conn: conn} do
      outro_user = insert(:user)
      outra_categoria = insert(:category, user: outro_user, name: "Privada")

      {:ok, view, _html} = live(conn, ~p"/categorias")

      html = render_click(view, "edit_category", %{"id" => outra_categoria.id})

      refute html =~ "modal-open"
    end
  end

  describe "exclusão de categoria" do
    setup %{conn: conn} do
      user = insert(:user)
      conn = init_test_session(conn, %{"user_id" => user.id})
      {:ok, conn: conn, user: user}
    end

    test "exibe botão de excluir para cada categoria", %{conn: conn, user: user} do
      insert(:category, user: user, name: "Alimentação")

      {:ok, _view, html} = live(conn, ~p"/categorias")

      assert html =~ "Excluir"
    end

    test "exclui categoria com sucesso e exibe flash", %{conn: conn, user: user} do
      insert(:category, user: user, name: "Alimentação")

      {:ok, view, _html} = live(conn, ~p"/categorias")

      html = view |> element("button", "Excluir") |> render_click()

      refute html =~ "Alimentação"
      assert html =~ "Categoria excluída com sucesso!"
    end

    test "não exclui categoria de outro usuário", %{conn: conn} do
      outro_user = insert(:user)
      outra_categoria = insert(:category, user: outro_user, name: "Privada")

      {:ok, view, _html} = live(conn, ~p"/categorias")

      html = render_click(view, "delete_category", %{"id" => outra_categoria.id})

      assert html =~ "Categoria não encontrada."
    end
  end
end
