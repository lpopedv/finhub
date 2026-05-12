defmodule FinhubWeb.TransactionLive.Index do
  use FinhubWeb, :live_view

  alias Core.Category.Services.ListCategoriesService
  alias Core.Repo
  alias Core.Schemas.Transaction
  alias Core.Transaction.Commands.ListTransactionsCommand
  alias Core.Transaction.Services.DeleteTransactionService
  alias Core.Transaction.Services.ListTransactionsService
  alias FinhubWeb.TransactionLive.FormComponent

  @spec mount(map(), map(), Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    transactions = list_transactions(user_id, "")
    categories = ListCategoriesService.execute(user_id)
    category_options = Enum.map(categories, &{&1.name, &1.id})

    socket =
      socket
      |> assign(page_title: "Transações")
      |> assign(:form_action, nil)
      |> assign(:editing_transaction, nil)
      |> assign(:confirm_delete_transaction, nil)
      |> assign(:category_options, category_options)
      |> assign(:search, "")
      |> assign(:transactions_count, length(transactions))
      |> stream(:transactions, transactions)

    {:ok, socket}
  end

  @spec handle_event(String.t(), map(), Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_event("search", %{"search" => search}, socket) do
    transactions = list_transactions(socket.assigns.current_user.id, search)

    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:transactions_count, length(transactions))
     |> stream(:transactions, transactions, reset: true)}
  end

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

  def handle_event("request_delete", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id

    case Repo.get_by(Transaction, id: id, user_id: user_id) do
      nil -> {:noreply, put_flash(socket, :error, "Transação não encontrada.")}
      transaction -> {:noreply, assign(socket, :confirm_delete_transaction, transaction)}
    end
  end

  def handle_event("cancel_delete", _params, socket),
    do: {:noreply, assign(socket, :confirm_delete_transaction, nil)}

  def handle_event("delete_transaction", _params, socket) do
    transaction = socket.assigns.confirm_delete_transaction

    case DeleteTransactionService.execute(transaction.id) do
      {:ok, deleted} ->
        {:noreply,
         socket
         |> stream_delete(:transactions, deleted)
         |> assign(:transactions_count, socket.assigns.transactions_count - 1)
         |> assign(:confirm_delete_transaction, nil)
         |> put_flash(:info, "Transação excluída com sucesso!")}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> assign(:confirm_delete_transaction, nil)
         |> put_flash(:error, "Transação não encontrada.")}
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

    count_delta = if socket.assigns.form_action == :new, do: 1, else: 0
    transaction = Repo.preload(transaction, :category)

    {:noreply,
     socket
     |> stream_insert(:transactions, transaction)
     |> assign(:transactions_count, socket.assigns.transactions_count + count_delta)
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
      <div class="flex flex-col gap-4 pb-6 border-b border-base-300 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 class="text-2xl font-bold tracking-tight">Transações</h1>
          <p class="mt-1 text-sm text-base-content/50">Histórico de receitas e despesas</p>
        </div>
        <div class="flex items-center gap-3">
          <form phx-change="search">
            <label class="input input-sm flex items-center gap-2 w-56">
              <.icon name="hero-magnifying-glass" class="size-4 shrink-0 text-base-content/40" />
              <input
                type="text"
                name="search"
                value={@search}
                placeholder="Buscar..."
                phx-debounce="300"
                class="grow bg-transparent outline-none"
              />
            </label>
          </form>
          <.button variant="primary" phx-click="new_transaction">
            <.icon name="hero-plus" class="size-4" /> Nova Transação
          </.button>
        </div>
      </div>

      <div
        :if={@transactions_count == 0}
        class="mt-16 flex flex-col items-center justify-center text-center"
      >
        <div class="rounded-full bg-base-200 p-6 mb-4">
          <.icon name="hero-arrows-right-left" class="size-10 text-base-content/30" />
        </div>
        <h3 class="text-lg font-semibold text-base-content/70">
          {if @search != "", do: "Nenhum resultado encontrado", else: "Nenhuma transação registrada"}
        </h3>
        <p class="mt-1 text-sm text-base-content/40 max-w-xs">
          {if @search != "",
            do: "Tente buscar por outro nome ou categoria",
            else: "Registre sua primeira receita ou despesa"}
        </p>
        <.button
          :if={@search == ""}
          class="btn btn-primary btn-sm mt-6"
          phx-click="new_transaction"
        >
          <.icon name="hero-plus" class="size-4" /> Nova Transação
        </.button>
      </div>

      <div class={[
        "mt-6 overflow-x-auto rounded-xl border border-base-300",
        @transactions_count == 0 && "hidden"
      ]}>
        <table class="table">
          <thead>
            <tr class="bg-base-200/60 border-b border-base-300 text-xs uppercase tracking-wide text-base-content/50">
              <th class="font-medium">Transação</th>
              <th class="font-medium">Data</th>
              <th class="font-medium">Categoria</th>
              <th class="font-medium text-right">Valor</th>
              <th></th>
            </tr>
          </thead>
          <tbody id="transactions" phx-update="stream">
            <tr
              :for={{id, t} <- @streams.transactions}
              id={id}
              class="border-b border-base-300/50 last:border-0 hover:bg-base-200/40 transition-colors duration-150 group"
            >
              <td class="py-3">
                <div class="flex items-center gap-3">
                  <div class={[
                    "shrink-0 rounded-lg p-2",
                    t.type == :income && "bg-success/10",
                    t.type == :expense && "bg-error/10"
                  ]}>
                    <.icon
                      name={
                        if t.type == :income, do: "hero-arrow-down-left", else: "hero-arrow-up-right"
                      }
                      class={[
                        "size-4",
                        t.type == :income && "text-success",
                        t.type == :expense && "text-error"
                      ]}
                    />
                  </div>
                  <div>
                    <p class="font-medium leading-tight">{t.name}</p>
                    <div class="flex items-center gap-1.5 mt-1">
                      <span class={[
                        "badge badge-xs",
                        t.type == :income && "badge-success",
                        t.type == :expense && "badge-error"
                      ]}>
                        {if t.type == :income, do: "Receita", else: "Despesa"}
                      </span>
                      <span :if={t.fixed_transaction_id} class="badge badge-xs badge-ghost gap-0.5">
                        <.icon name="hero-arrow-path" class="size-2.5" /> Fixa
                      </span>
                    </div>
                  </div>
                </div>
              </td>
              <td class="py-3 text-sm text-base-content/60 tabular-nums">
                {Calendar.strftime(t.date, "%d/%m/%Y")}
              </td>
              <td class="py-3">
                <span :if={t.category} class="badge badge-ghost badge-sm">{t.category.name}</span>
                <span :if={!t.category} class="text-base-content/30 text-sm">—</span>
              </td>
              <td class="py-3 text-right">
                <span class={[
                  "font-semibold tabular-nums",
                  t.type == :income && "text-success",
                  t.type == :expense && "text-error"
                ]}>
                  {format_brl(t.value_in_cents)}
                </span>
              </td>
              <td class="py-3 w-0">
                <div class="flex gap-1 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity duration-150">
                  <.button
                    class="btn btn-ghost btn-xs btn-circle tooltip tooltip-left"
                    data-tip="Editar"
                    phx-click="edit_transaction"
                    phx-value-id={t.id}
                  >
                    <.icon name="hero-pencil-square" class="size-4" />
                  </.button>
                  <.button
                    class="btn btn-ghost btn-xs btn-circle text-error tooltip tooltip-left"
                    data-tip="Excluir"
                    phx-click="request_delete"
                    phx-value-id={t.id}
                  >
                    <.icon name="hero-trash" class="size-4" />
                  </.button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <.live_component
        :if={@form_action}
        module={FormComponent}
        id="transaction-form"
        action={@form_action}
        transaction={@editing_transaction}
        current_user={@current_user}
        category_options={@category_options}
      />

      <dialog :if={@confirm_delete_transaction} id="confirm-delete-modal" class="modal modal-open">
        <div class="modal-box max-w-sm">
          <div class="flex items-center gap-3 mb-4">
            <div class="shrink-0 rounded-full bg-error/10 p-3">
              <.icon name="hero-trash" class="size-5 text-error" />
            </div>
            <div>
              <h3 class="text-lg font-bold">Excluir transação</h3>
              <p class="text-sm text-base-content/50">Esta ação não pode ser desfeita</p>
            </div>
          </div>
          <p class="text-sm text-base-content/70">
            Tem certeza que deseja excluir a transação <span class="font-semibold text-base-content">
              {@confirm_delete_transaction.name}
            </span>?
          </p>
          <div class="modal-action mt-6 pt-4 border-t border-base-300">
            <.button class="btn btn-ghost" phx-click="cancel_delete">Cancelar</.button>
            <.button class="btn btn-error" phx-click="delete_transaction">
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

  defp list_transactions(user_id, search) do
    command = ListTransactionsCommand.build!(%{user_id: user_id, search: search})
    ListTransactionsService.execute(command)
  end
end
