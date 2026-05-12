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
      |> assign(:confirm_delete_category, nil)
      |> assign(:categories_count, length(categories))
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

  def handle_event("request_delete", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id

    case Repo.get_by(Category, id: id, user_id: user_id) do
      nil -> {:noreply, put_flash(socket, :error, "Categoria não encontrada.")}
      category -> {:noreply, assign(socket, :confirm_delete_category, category)}
    end
  end

  def handle_event("cancel_delete", _params, socket),
    do: {:noreply, assign(socket, :confirm_delete_category, nil)}

  def handle_event("delete_category", _params, socket) do
    category = socket.assigns.confirm_delete_category

    case DeleteCategoryService.execute(category.id) do
      {:ok, deleted} ->
        {:noreply,
         socket
         |> stream_delete(:categories, deleted)
         |> assign(:categories_count, socket.assigns.categories_count - 1)
         |> assign(:confirm_delete_category, nil)
         |> put_flash(:info, "Categoria excluída com sucesso!")}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> assign(:confirm_delete_category, nil)
         |> put_flash(:error, "Categoria não encontrada.")}
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

    count_delta = if socket.assigns.form_action == :new, do: 1, else: 0

    {:noreply,
     socket
     |> stream_insert(:categories, category)
     |> assign(:categories_count, socket.assigns.categories_count + count_delta)
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
      <div class="flex items-center justify-between pb-6 border-b border-base-300">
        <div>
          <h1 class="text-2xl font-bold tracking-tight">Categorias</h1>
          <p class="mt-1 text-sm text-base-content/50">Organize suas transações por categoria</p>
        </div>
        <.button variant="primary" phx-click="new_category">
          <.icon name="hero-plus" class="size-4" /> Nova Categoria
        </.button>
      </div>

      <div
        :if={@categories_count == 0}
        class="mt-16 flex flex-col items-center justify-center text-center"
      >
        <div class="rounded-full bg-base-200 p-6 mb-4">
          <.icon name="hero-tag" class="size-10 text-base-content/30" />
        </div>
        <h3 class="text-lg font-semibold text-base-content/70">Nenhuma categoria criada</h3>
        <p class="mt-1 text-sm text-base-content/40 max-w-xs">
          Crie categorias para organizar suas receitas e despesas
        </p>
        <.button class="btn btn-primary btn-sm mt-6" phx-click="new_category">
          <.icon name="hero-plus" class="size-4" /> Criar primeira categoria
        </.button>
      </div>

      <div
        id="categories"
        phx-update="stream"
        class="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3"
      >
        <div
          :for={{id, category} <- @streams.categories}
          id={id}
          class="card bg-base-200 shadow-sm hover:shadow-md hover:bg-base-300/50 transition-all duration-300 group"
        >
          <div class="card-body gap-3">
            <div class="flex items-start justify-between gap-2">
              <div class="flex items-center gap-3 min-w-0">
                <div class="shrink-0 rounded-lg bg-primary/10 p-2.5">
                  <.icon name="hero-tag" class="size-5 text-primary" />
                </div>
                <h3 class="font-semibold text-base truncate">{category.name}</h3>
              </div>
              <div class="flex shrink-0 gap-1 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity duration-150">
                <.button
                  class="btn btn-ghost btn-xs btn-circle tooltip tooltip-left"
                  data-tip="Editar"
                  phx-click="edit_category"
                  phx-value-id={category.id}
                >
                  <.icon name="hero-pencil-square" class="size-4" />
                </.button>
                <.button
                  class="btn btn-ghost btn-xs btn-circle text-error tooltip tooltip-left"
                  data-tip="Excluir"
                  phx-click="request_delete"
                  phx-value-id={category.id}
                >
                  <.icon name="hero-trash" class="size-4" />
                </.button>
              </div>
            </div>
            <p class="text-sm text-base-content/60 leading-relaxed line-clamp-2">
              {if category.description && category.description != "",
                do: category.description,
                else: "Sem descrição"}
            </p>
          </div>
        </div>
      </div>

      <.live_component
        :if={@form_action}
        module={FormComponent}
        id="category-form"
        action={@form_action}
        category={@editing_category}
        current_user={@current_user}
      />

      <dialog :if={@confirm_delete_category} id="confirm-delete-modal" class="modal modal-open">
        <div class="modal-box max-w-sm">
          <div class="flex items-center gap-3 mb-4">
            <div class="shrink-0 rounded-full bg-error/10 p-3">
              <.icon name="hero-trash" class="size-5 text-error" />
            </div>
            <div>
              <h3 class="text-lg font-bold">Excluir categoria</h3>
              <p class="text-sm text-base-content/50">Esta ação não pode ser desfeita</p>
            </div>
          </div>
          <p class="text-sm text-base-content/70">
            Tem certeza que deseja excluir a categoria <span class="font-semibold text-base-content">
              {@confirm_delete_category.name}
            </span>?
          </p>
          <div class="modal-action mt-6 pt-4 border-t border-base-300">
            <.button class="btn btn-ghost" phx-click="cancel_delete">Cancelar</.button>
            <.button class="btn btn-error" phx-click="delete_category">
              <.icon name="hero-trash" class="size-4" /> Excluir
            </.button>
          </div>
        </div>
        <div class="modal-backdrop">
          <button phx-click="cancel_delete">fechar</button>
        </div>
      </dialog>
    </Layouts.app>
    """
  end
end
