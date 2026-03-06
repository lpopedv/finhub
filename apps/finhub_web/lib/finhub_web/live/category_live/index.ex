defmodule FinhubWeb.CategoryLive.Index do
  use FinhubWeb, :live_view

  alias Core.Category.Services.DeleteCategoryService
  alias Core.Category.Services.ListCategoriesService
  alias Core.Repo
  alias Core.Schemas.Category
  alias FinhubWeb.CategoryLive.FormComponent

  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    categories = ListCategoriesService.execute(socket.assigns.current_user.id)

    socket =
      socket
      |> assign(page_title: "Categorias")
      |> assign(:form_action, nil)
      |> assign(:editing_category, nil)
      |> stream(:categories, categories)

    {:ok, socket}
  end

  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("new_category", _params, socket),
    do:
      {:noreply,
       socket
       |> assign(:form_action, :new)
       |> assign(:editing_category, nil)}

  def handle_event("edit_category", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id

    case Repo.get_by(Category, id: id, user_id: user_id) do
      nil ->
        {:noreply, socket}

      category ->
        {:noreply,
         socket
         |> assign(:form_action, :edit)
         |> assign(:editing_category, category)}
    end
  end

  def handle_event("delete_category", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id

    case Repo.get_by(Category, id: id, user_id: user_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Categoria não encontrada.")}

      category ->
        case DeleteCategoryService.execute(category.id) do
          {:ok, deleted} ->
            {:noreply,
             socket
             |> stream_delete(:categories, deleted)
             |> put_flash(:info, "Categoria excluída com sucesso!")}

          {:error, :not_found} ->
            {:noreply, put_flash(socket, :error, "Categoria não encontrada.")}
        end
    end
  end

  def handle_event("close_form", _params, socket),
    do:
      {:noreply,
       socket
       |> assign(:form_action, nil)
       |> assign(:editing_category, nil)}

  @spec handle_info(tuple(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({:saved, category}, socket) do
    flash_msg =
      case socket.assigns.form_action do
        :new -> "Categoria criada com sucesso!"
        :edit -> "Categoria atualizada com sucesso!"
      end

    {:noreply,
     socket
     |> stream_insert(:categories, category)
     |> assign(:form_action, nil)
     |> assign(:editing_category, nil)
     |> put_flash(:info, flash_msg)}
  end

  def handle_info({:error, :not_found}, socket),
    do:
      {:noreply,
       socket
       |> assign(:form_action, nil)
       |> assign(:editing_category, nil)
       |> put_flash(:error, "Categoria não encontrada.")}

  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Categorias
        <:actions>
          <.button phx-click="new_category" variant="primary">Nova Categoria</.button>
        </:actions>
      </.header>

      <.table id="categories" rows={@streams.categories}>
        <:col :let={{_id, category}} label="Nome">{category.name}</:col>
        <:col :let={{_id, category}} label="Descrição">{category.description}</:col>
        <:action :let={{_id, category}}>
          <.button phx-click="edit_category" phx-value-id={category.id}>Editar</.button>
          <.button
            phx-click="delete_category"
            phx-value-id={category.id}
            data-confirm="Tem certeza que deseja excluir esta categoria?"
          >
            Excluir
          </.button>
        </:action>
      </.table>

      <.live_component
        :if={@form_action}
        module={FormComponent}
        id="category-form"
        action={@form_action}
        category={@editing_category}
        current_user={@current_user}
      />
    </Layouts.app>
    """
  end
end
