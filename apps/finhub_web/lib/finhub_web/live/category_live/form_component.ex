defmodule FinhubWeb.CategoryLive.FormComponent do
  use FinhubWeb, :live_component

  alias Core.Category.Commands.CreateCategoryCommand
  alias Core.Category.Services.CreateCategoryService
  alias Core.Category.Services.UpdateCategoryService
  alias Core.Schemas.Category

  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <dialog id="category-form-modal" class="modal modal-open">
      <div class="modal-box">
        <h3 class="text-lg font-semibold mb-4">
          {if @action == :new, do: "Nova Categoria", else: "Editar Categoria"}
        </h3>
        <.form for={@form} phx-change="validate" phx-submit="save" phx-target={@myself}>
          <.input field={@form[:name]} label="Nome" />
          <.input field={@form[:description]} label="Descrição" />
          <div class="modal-action">
            <.button type="button" phx-click="close_form">Cancelar</.button>
            <.button type="submit" variant="primary">Salvar</.button>
          </div>
        </.form>
      </div>
      <div class="modal-backdrop">
        <button type="button" phx-click="close_form">fechar</button>
      </div>
    </dialog>
    """
  end

  @spec update(map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form()}
  end

  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("validate", %{"category" => params}, socket) do
    form =
      socket
      |> build_changeset(params)
      |> Map.put(:action, :validate)
      |> to_form(as: "category")

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"category" => params}, socket) do
    case save_category(socket, params) do
      {:ok, category} ->
        notify_parent({:saved, category})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "category"))}

      {:error, :not_found} ->
        notify_parent({:error, :not_found})
        {:noreply, socket}
    end
  end

  defp assign_form(%{assigns: %{action: :new}} = socket) do
    assign(socket, :form, to_form(CreateCategoryCommand.changeset(%{}), as: "category"))
  end

  defp assign_form(%{assigns: %{action: :edit, category: category}} = socket) do
    assign(socket, :form, to_form(Category.changeset(category, %{}), as: "category"))
  end

  defp build_changeset(%{assigns: %{action: :new}}, params) do
    CreateCategoryCommand.changeset(params)
  end

  defp build_changeset(%{assigns: %{action: :edit, category: category}}, params) do
    Category.changeset(category, params)
  end

  defp save_category(%{assigns: %{action: :new, current_user: user}}, params) do
    command = %CreateCategoryCommand{
      user_id: user.id,
      name: params["name"],
      description: params["description"]
    }

    CreateCategoryService.execute(command)
  end

  defp save_category(%{assigns: %{action: :edit, category: category}}, params) do
    UpdateCategoryService.execute(category.id, params)
  end

  defp notify_parent(msg), do: send(self(), msg)
end
