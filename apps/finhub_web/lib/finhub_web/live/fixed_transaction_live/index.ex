defmodule FinhubWeb.FixedTransactionLive.Index do
  use FinhubWeb, :live_view

  alias Core.Category.Services.ListCategoriesService
  alias Core.FixedTransaction.Services.DeleteFixedTransactionService
  alias Core.FixedTransaction.Services.ListFixedTransactionsService
  alias Core.Repo
  alias Core.Schemas.FixedTransaction
  alias FinhubWeb.FixedTransactionLive.FormComponent

  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    fixed_transactions = ListFixedTransactionsService.execute(user_id)
    categories = ListCategoriesService.execute(user_id)
    category_options = Enum.map(categories, &{&1.name, &1.id})

    socket =
      socket
      |> assign(page_title: "Transações Fixas")
      |> assign(:form_action, nil)
      |> assign(:editing_fixed_transaction, nil)
      |> assign(:category_options, category_options)
      |> stream(:fixed_transactions, fixed_transactions)

    {:ok, socket}
  end

  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("new_fixed_transaction", _params, socket),
    do:
      {:noreply,
       socket
       |> assign(:form_action, :new)
       |> assign(:editing_fixed_transaction, nil)}

  def handle_event("edit_fixed_transaction", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id

    case Repo.get_by(FixedTransaction, id: id, user_id: user_id) do
      nil ->
        {:noreply, socket}

      fixed_transaction ->
        {:noreply,
         socket
         |> assign(:form_action, :edit)
         |> assign(:editing_fixed_transaction, fixed_transaction)}
    end
  end

  def handle_event("delete_fixed_transaction", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id

    case Repo.get_by(FixedTransaction, id: id, user_id: user_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Transação fixa não encontrada.")}

      fixed_transaction ->
        case DeleteFixedTransactionService.execute(fixed_transaction.id) do
          {:ok, deleted} ->
            {:noreply,
             socket
             |> stream_delete(:fixed_transactions, deleted)
             |> put_flash(:info, "Transação fixa excluída com sucesso!")}

          {:error, :not_found} ->
            {:noreply, put_flash(socket, :error, "Transação fixa não encontrada.")}
        end
    end
  end

  def handle_event("close_form", _params, socket),
    do:
      {:noreply,
       socket
       |> assign(:form_action, nil)
       |> assign(:editing_fixed_transaction, nil)}

  @spec handle_info(tuple(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({:saved, fixed_transaction}, socket) do
    flash_msg =
      case socket.assigns.form_action do
        :new -> "Transação fixa criada com sucesso!"
        :edit -> "Transação fixa atualizada com sucesso!"
      end

    {:noreply,
     socket
     |> stream_insert(:fixed_transactions, fixed_transaction)
     |> assign(:form_action, nil)
     |> assign(:editing_fixed_transaction, nil)
     |> put_flash(:info, flash_msg)}
  end

  def handle_info({:error, :not_found}, socket),
    do:
      {:noreply,
       socket
       |> assign(:form_action, nil)
       |> assign(:editing_fixed_transaction, nil)
       |> put_flash(:error, "Transação fixa não encontrada.")}

  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Transações Fixas
        <:actions>
          <.button phx-click="new_fixed_transaction" variant="primary">Nova Transação Fixa</.button>
        </:actions>
      </.header>

      <.table id="fixed-transactions" rows={@streams.fixed_transactions}>
        <:col :let={{_id, ft}} label="Nome">{ft.name}</:col>
        <:col :let={{_id, ft}} label="Dia do Mês">{ft.day_of_month}</:col>
        <:col :let={{_id, ft}} label="Valor">{format_brl(ft.value_in_cents)}</:col>
        <:action :let={{_id, ft}}>
          <.button phx-click="edit_fixed_transaction" phx-value-id={ft.id}>Editar</.button>
          <.button
            phx-click="delete_fixed_transaction"
            phx-value-id={ft.id}
            data-confirm="Tem certeza que deseja excluir esta transação fixa?"
          >
            Excluir
          </.button>
        </:action>
      </.table>

      <.live_component
        :if={@form_action}
        module={FormComponent}
        id="fixed-transaction-form"
        action={@form_action}
        fixed_transaction={@editing_fixed_transaction}
        current_user={@current_user}
        category_options={@category_options}
      />
    </Layouts.app>
    """
  end
end
