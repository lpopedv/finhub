defmodule FinhubWeb.TransactionLive.FormComponent do
  use FinhubWeb, :live_component

  alias Core.Schemas.Transaction
  alias Core.Transaction.Commands.CreateTransactionCommand
  alias Core.Transaction.Services.CreateTransactionService
  alias Core.Transaction.Services.UpdateTransactionService

  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <dialog id="transaction-form-modal" class="modal modal-open">
      <div class="modal-box">
        <h3 class="text-lg font-semibold mb-4">
          {if @action == :new, do: "Nova Transação", else: "Editar Transação"}
        </h3>
        <.form for={@form} phx-change="validate" phx-submit="save" phx-target={@myself}>
          <.input field={@form[:name]} label="Nome" />
          <.input field={@form[:value_in_cents]} type="number" label="Valor (centavos)" />
          <.input
            field={@form[:category_id]}
            type="select"
            label="Categoria"
            options={@category_options}
            prompt="Sem categoria"
          />
          <.input field={@form[:is_fixed]} type="checkbox" label="Fixo" />
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
  def update(assigns, socket),
    do:
      {:ok,
       socket
       |> assign(assigns)
       |> assign_form()}

  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("validate", %{"transaction" => params}, socket) do
    form =
      socket
      |> build_changeset(normalize_params(params))
      |> Map.put(:action, :validate)
      |> to_form(as: "transaction")

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"transaction" => params}, socket) do
    case save_transaction(socket, normalize_params(params)) do
      {:ok, transaction} ->
        notify_parent({:saved, transaction})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "transaction"))}

      {:error, :not_found} ->
        notify_parent({:error, :not_found})
        {:noreply, socket}
    end
  end

  defp assign_form(socket),
    do:
      assign(
        socket,
        :form,
        socket
        |> build_changeset(%{})
        |> to_form(as: "transaction")
      )

  defp build_changeset(%{assigns: %{action: :new}}, params),
    do: CreateTransactionCommand.changeset(params)

  defp build_changeset(%{assigns: %{action: :edit, transaction: transaction}}, params),
    do: Transaction.changeset(transaction, params)

  defp save_transaction(%{assigns: %{action: :new, current_user: user}}, params) do
    command = %CreateTransactionCommand{
      user_id: user.id,
      name: params["name"],
      value_in_cents: params["value_in_cents"],
      category_id: params["category_id"],
      is_fixed: params["is_fixed"]
    }

    CreateTransactionService.execute(command)
  end

  defp save_transaction(%{assigns: %{action: :edit, transaction: transaction}}, params),
    do: UpdateTransactionService.execute(transaction.id, params)

  defp normalize_params(params) do
    Map.update(params, "category_id", nil, fn
      "" -> nil
      id -> id
    end)
  end

  defp notify_parent(msg), do: send(self(), msg)
end
