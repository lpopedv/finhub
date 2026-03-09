defmodule FinhubWeb.FixedTransactionLive.FormComponent do
  use FinhubWeb, :live_component

  alias Core.FixedTransaction.Commands.CreateFixedTransactionCommand
  alias Core.FixedTransaction.Services.CreateFixedTransactionService
  alias Core.FixedTransaction.Services.UpdateFixedTransactionService
  alias Core.Schemas.FixedTransaction

  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <dialog id="fixed-transaction-form-modal" class="modal modal-open">
      <div class="modal-box">
        <h3 class="text-lg font-semibold mb-4">
          {if @action == :new, do: "Nova Transação Fixa", else: "Editar Transação Fixa"}
        </h3>
        <.form for={@form} phx-change="validate" phx-submit="save" phx-target={@myself}>
          <.input field={@form[:name]} label="Nome" />
          <.input field={@form[:day_of_month]} type="number" label="Dia do Mês" />
          <.input field={@form[:value_in_cents]} type="number" label="Valor (centavos)" />
          <.input
            field={@form[:category_id]}
            type="select"
            label="Categoria"
            options={@category_options}
            prompt="Sem categoria"
          />
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
  def handle_event("validate", %{"fixed_transaction" => params}, socket) do
    form =
      socket
      |> build_changeset(normalize_params(params))
      |> Map.put(:action, :validate)
      |> to_form(as: "fixed_transaction")

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"fixed_transaction" => params}, socket) do
    case save_fixed_transaction(socket, normalize_params(params)) do
      {:ok, fixed_transaction} ->
        notify_parent({:saved, fixed_transaction})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: "fixed_transaction"))}

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
        |> to_form(as: "fixed_transaction")
      )

  defp build_changeset(%{assigns: %{action: :new}}, params),
    do: CreateFixedTransactionCommand.changeset(params)

  defp build_changeset(
         %{assigns: %{action: :edit, fixed_transaction: fixed_transaction}},
         params
       ),
       do: FixedTransaction.changeset(fixed_transaction, params)

  defp save_fixed_transaction(%{assigns: %{action: :new, current_user: user}}, params) do
    command = %CreateFixedTransactionCommand{
      user_id: user.id,
      name: params["name"],
      value_in_cents: params["value_in_cents"],
      category_id: params["category_id"],
      day_of_month: params["day_of_month"]
    }

    CreateFixedTransactionService.execute(command)
  end

  defp save_fixed_transaction(
         %{assigns: %{action: :edit, fixed_transaction: fixed_transaction}},
         params
       ),
       do: UpdateFixedTransactionService.execute(fixed_transaction.id, params)

  defp normalize_params(params) do
    Map.update(params, "category_id", nil, fn
      "" -> nil
      id -> id
    end)
  end

  defp notify_parent(msg), do: send(self(), msg)
end
