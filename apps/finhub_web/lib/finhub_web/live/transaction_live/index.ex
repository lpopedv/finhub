defmodule FinhubWeb.TransactionLive.Index do
  use FinhubWeb, :live_view

  alias Core.Category.Services.ListCategoriesService
  alias Core.Repo
  alias Core.Schemas.Transaction
  alias Core.Transaction.Services.DeleteTransactionService
  alias Core.Transaction.Services.ListTransactionsService
  alias FinhubWeb.TransactionLive.FormComponent

  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    transactions = ListTransactionsService.execute(user_id)
    categories = ListCategoriesService.execute(user_id)
    category_options = Enum.map(categories, &{&1.name, &1.id})

    socket =
      socket
      |> assign(page_title: "Transações")
      |> assign(:form_action, nil)
      |> assign(:editing_transaction, nil)
      |> assign(:category_options, category_options)
      |> stream(:transactions, transactions)

    {:ok, socket}
  end

  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("new_transaction", _params, socket),
    do:
      {:noreply,
       socket
       |> assign(:form_action, :new)
       |> assign(:editing_transaction, nil)}

  def handle_event("edit_transaction", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id

    case Repo.get_by(Transaction, id: id, user_id: user_id) do
      nil ->
        {:noreply, socket}

      transaction ->
        {:noreply,
         socket
         |> assign(:form_action, :edit)
         |> assign(:editing_transaction, transaction)}
    end
  end

  def handle_event("delete_transaction", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id

    case Repo.get_by(Transaction, id: id, user_id: user_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Transação não encontrada.")}

      transaction ->
        case DeleteTransactionService.execute(transaction.id) do
          {:ok, deleted} ->
            {:noreply,
             socket
             |> stream_delete(:transactions, deleted)
             |> put_flash(:info, "Transação excluída com sucesso!")}

          {:error, :not_found} ->
            {:noreply, put_flash(socket, :error, "Transação não encontrada.")}
        end
    end
  end

  def handle_event("close_form", _params, socket),
    do:
      {:noreply,
       socket
       |> assign(:form_action, nil)
       |> assign(:editing_transaction, nil)}

  @spec handle_info(tuple(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({:saved, transaction}, socket) do
    flash_msg =
      case socket.assigns.form_action do
        :new -> "Transação criada com sucesso!"
        :edit -> "Transação atualizada com sucesso!"
      end

    {:noreply,
     socket
     |> stream_insert(:transactions, transaction)
     |> assign(:form_action, nil)
     |> assign(:editing_transaction, nil)
     |> put_flash(:info, flash_msg)}
  end

  def handle_info({:error, :not_found}, socket),
    do:
      {:noreply,
       socket
       |> assign(:form_action, nil)
       |> assign(:editing_transaction, nil)
       |> put_flash(:error, "Transação não encontrada.")}

  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Transações
        <:actions>
          <.button phx-click="new_transaction" variant="primary">Nova Transação</.button>
        </:actions>
      </.header>

      <.table id="transactions" rows={@streams.transactions}>
        <:col :let={{_id, transaction}} label="Nome">{transaction.name}</:col>
        <:col :let={{_id, transaction}} label="Data">
          {Calendar.strftime(transaction.date, "%d/%m/%Y")}
        </:col>
        <:col :let={{_id, transaction}} label="Valor (centavos)">{transaction.value_in_cents}</:col>
        <:action :let={{_id, transaction}}>
          <.button phx-click="edit_transaction" phx-value-id={transaction.id}>Editar</.button>
          <.button
            phx-click="delete_transaction"
            phx-value-id={transaction.id}
            data-confirm="Tem certeza que deseja excluir esta transação?"
          >
            Excluir
          </.button>
        </:action>
      </.table>

      <.live_component
        :if={@form_action}
        module={FormComponent}
        id="transaction-form"
        action={@form_action}
        transaction={@editing_transaction}
        current_user={@current_user}
        category_options={@category_options}
      />
    </Layouts.app>
    """
  end
end
