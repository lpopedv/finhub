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

    fixed_transactions =
      user_id
      |> ListFixedTransactionsService.execute()
      |> Repo.preload(:category)

    categories = ListCategoriesService.execute(user_id)
    category_options = Enum.map(categories, &{&1.name, &1.id})

    socket =
      socket
      |> assign(page_title: "Transações Fixas")
      |> assign(:form_action, nil)
      |> assign(:editing_fixed_transaction, nil)
      |> assign(:confirm_delete_fixed_transaction, nil)
      |> assign(:category_options, category_options)
      |> assign(:fixed_transactions_count, length(fixed_transactions))
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

  def handle_event("request_delete", %{"id" => id}, socket) do
    user_id = socket.assigns.current_user.id

    case Repo.get_by(FixedTransaction, id: id, user_id: user_id) do
      nil -> {:noreply, put_flash(socket, :error, "Transação fixa não encontrada.")}
      ft -> {:noreply, assign(socket, :confirm_delete_fixed_transaction, ft)}
    end
  end

  def handle_event("cancel_delete", _params, socket),
    do: {:noreply, assign(socket, :confirm_delete_fixed_transaction, nil)}

  def handle_event("delete_fixed_transaction", _params, socket) do
    ft = socket.assigns.confirm_delete_fixed_transaction

    case DeleteFixedTransactionService.execute(ft.id) do
      {:ok, deleted} ->
        {:noreply,
         socket
         |> stream_delete(:fixed_transactions, deleted)
         |> assign(:fixed_transactions_count, socket.assigns.fixed_transactions_count - 1)
         |> assign(:confirm_delete_fixed_transaction, nil)
         |> put_flash(:info, "Transação fixa excluída com sucesso!")}

      {:error, :not_found} ->
        {:noreply,
         socket
         |> assign(:confirm_delete_fixed_transaction, nil)
         |> put_flash(:error, "Transação fixa não encontrada.")}
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

    count_delta = if socket.assigns.form_action == :new, do: 1, else: 0
    fixed_transaction = Repo.preload(fixed_transaction, :category)

    {:noreply,
     socket
     |> stream_insert(:fixed_transactions, fixed_transaction)
     |> assign(:fixed_transactions_count, socket.assigns.fixed_transactions_count + count_delta)
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
      <div class="flex items-center justify-between pb-6 border-b border-base-300">
        <div>
          <h1 class="text-2xl font-bold tracking-tight">Transações Fixas</h1>
          <p class="mt-1 text-sm text-base-content/50">
            Receitas e despesas que se repetem mensalmente
          </p>
        </div>
        <.button variant="primary" phx-click="new_fixed_transaction">
          <.icon name="hero-plus" class="size-4" /> Nova Transação Fixa
        </.button>
      </div>

      <div
        :if={@fixed_transactions_count == 0}
        class="mt-16 flex flex-col items-center justify-center text-center"
      >
        <div class="rounded-full bg-base-200 p-6 mb-4">
          <.icon name="hero-arrow-path" class="size-10 text-base-content/30" />
        </div>
        <h3 class="text-lg font-semibold text-base-content/70">Nenhuma transação fixa cadastrada</h3>
        <p class="mt-1 text-sm text-base-content/40 max-w-xs">
          Cadastre suas despesas e receitas recorrentes mensais
        </p>
        <.button class="btn btn-primary btn-sm mt-6" phx-click="new_fixed_transaction">
          <.icon name="hero-plus" class="size-4" /> Cadastrar primeira transação fixa
        </.button>
      </div>

      <div class={[
        "mt-6 overflow-x-auto rounded-xl border border-base-300",
        @fixed_transactions_count == 0 && "hidden"
      ]}>
        <table class="table">
          <thead>
            <tr class="bg-base-200/60 border-b border-base-300 text-xs uppercase tracking-wide text-base-content/50">
              <th class="font-medium">Transação</th>
              <th class="font-medium">Dia do mês</th>
              <th class="font-medium">Categoria</th>
              <th class="font-medium text-right">Valor</th>
              <th></th>
            </tr>
          </thead>
          <tbody id="fixed-transactions" phx-update="stream">
            <tr
              :for={{id, ft} <- @streams.fixed_transactions}
              id={id}
              class="border-b border-base-300/50 last:border-0 hover:bg-base-200/40 transition-colors duration-150 group"
            >
              <td class="py-3">
                <div class="flex items-center gap-3">
                  <div class={[
                    "shrink-0 rounded-lg p-2",
                    ft.type == :income && "bg-success/10",
                    ft.type == :expense && "bg-error/10"
                  ]}>
                    <.icon
                      name={
                        if ft.type == :income, do: "hero-arrow-down-left", else: "hero-arrow-up-right"
                      }
                      class={[
                        "size-4",
                        ft.type == :income && "text-success",
                        ft.type == :expense && "text-error"
                      ]}
                    />
                  </div>
                  <div>
                    <p class="font-medium leading-tight">{ft.name}</p>
                    <div class="flex items-center gap-1.5 mt-1">
                      <span class={[
                        "badge badge-xs",
                        ft.type == :income && "badge-success",
                        ft.type == :expense && "badge-error"
                      ]}>
                        {if ft.type == :income, do: "Receita", else: "Despesa"}
                      </span>
                      <span class={[
                        "badge badge-xs",
                        ft.active && "badge-ghost",
                        !ft.active && "badge-warning"
                      ]}>
                        {if ft.active, do: "Ativa", else: "Inativa"}
                      </span>
                    </div>
                  </div>
                </div>
              </td>
              <td class="py-3 text-sm text-base-content/60 tabular-nums">
                Dia {ft.day_of_month}
              </td>
              <td class="py-3">
                <span :if={ft.category} class="badge badge-ghost badge-sm">{ft.category.name}</span>
                <span :if={!ft.category} class="text-base-content/30 text-sm">—</span>
              </td>
              <td class="py-3 text-right">
                <span class={[
                  "font-semibold tabular-nums",
                  ft.type == :income && "text-success",
                  ft.type == :expense && "text-error"
                ]}>
                  {format_brl(ft.value_in_cents)}
                </span>
              </td>
              <td class="py-3 w-0">
                <div class="flex gap-1 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 transition-opacity duration-150">
                  <.button
                    class="btn btn-ghost btn-xs btn-circle tooltip tooltip-left"
                    data-tip="Editar"
                    phx-click="edit_fixed_transaction"
                    phx-value-id={ft.id}
                  >
                    <.icon name="hero-pencil-square" class="size-4" />
                  </.button>
                  <.button
                    class="btn btn-ghost btn-xs btn-circle text-error tooltip tooltip-left"
                    data-tip="Excluir"
                    phx-click="request_delete"
                    phx-value-id={ft.id}
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
        id="fixed-transaction-form"
        action={@form_action}
        fixed_transaction={@editing_fixed_transaction}
        current_user={@current_user}
        category_options={@category_options}
      />

      <dialog
        :if={@confirm_delete_fixed_transaction}
        id="confirm-delete-modal"
        class="modal modal-open"
      >
        <div class="modal-box max-w-sm">
          <div class="flex items-center gap-3 mb-4">
            <div class="shrink-0 rounded-full bg-error/10 p-3">
              <.icon name="hero-trash" class="size-5 text-error" />
            </div>
            <div>
              <h3 class="text-lg font-bold">Excluir transação fixa</h3>
              <p class="text-sm text-base-content/50">Esta ação não pode ser desfeita</p>
            </div>
          </div>
          <p class="text-sm text-base-content/70">
            Tem certeza que deseja excluir a transação fixa <span class="font-semibold text-base-content">
              {@confirm_delete_fixed_transaction.name}
            </span>?
          </p>
          <div class="modal-action mt-6 pt-4 border-t border-base-300">
            <.button class="btn btn-ghost" phx-click="cancel_delete">Cancelar</.button>
            <.button class="btn btn-error" phx-click="delete_fixed_transaction">
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
