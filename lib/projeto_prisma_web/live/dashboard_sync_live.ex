defmodule ProjetoPrismaWeb.DashboardSyncLive do
  use ProjetoPrismaWeb, :live_view

  alias ProjetoPrisma.Accounts

  @impl true
  def mount(_params, %{"profile_id" => profile_id} = _session, socket) do
    topic = "sync:profile:#{profile_id}"

    if connected?(socket) do
      Phoenix.PubSub.subscribe(ProjetoPrisma.PubSub, topic)
    end

    accounts = Accounts.list_connected_platform_accounts(profile_id)
    running_accounts = Enum.filter(accounts, &(&1.sync_status == "running"))
    failed_accounts = Enum.filter(accounts, &(&1.sync_status == "failed"))
    pending_accounts = Enum.filter(accounts, &pending_sync_account?/1)
    initial_status = determine_status(running_accounts, failed_accounts, pending_accounts)

    assigns = %{
      profile_id: profile_id,
      status: initial_status,
      count: initial_count(initial_status, running_accounts, failed_accounts, pending_accounts),
      title: initial_title(running_accounts, failed_accounts, pending_accounts),
      message: initial_message(running_accounts, failed_accounts, pending_accounts),
      progress: initial_status in [:running, :idle],
      progress_percent: 0,
      games_info: "",
      total_games: 0,
      minimized: false
    }

    {:ok, assign(socket, assigns)}
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_info({:sync_event, %{type: "sync:start", total: total}}, socket) do
    {:noreply,
     socket
     |> assign(:status, :running)
     |> assign(:minimized, false)
     |> assign(:count, total)
     |> assign(:title, "Sincronização em andamento")
     |> assign(:message, "Sincronizando suas contas em segundo plano.")
     |> assign(:progress, true)
     |> assign(:progress_percent, 2)
     |> assign(:games_info, "")}
  end

  def handle_info({:sync_event, %{type: "games:total", total_games: total}}, socket) do
    {:noreply,
     socket
     |> assign(:total_games, total)
     |> assign(:games_info, "Iniciando sincronização de #{total} jogo(s)...")}
  end

  def handle_info(
        {:sync_event,
         %{
           type: "game:synced",
           current: current,
           total: total,
           progress_percent: percent,
           achievements_count: ach_count
         }},
        socket
      ) do
    new_message = "#{current} de #{total} jogos sincronizados (#{ach_count} conquistas)"

    {:noreply,
     socket
     |> assign(:progress_percent, percent)
     |> assign(:message, new_message)
     |> assign(:games_info, new_message)}
  end

  def handle_info(
        {:sync_event,
         %{type: "game:failed", current: current, total: total, progress_percent: percent}},
        socket
      ) do
    {:noreply,
     socket
     |> assign(:progress_percent, percent)
     |> assign(:games_info, "#{current} de #{total} jogos processados (alguns com erro)")}
  end

  def handle_info(
        {:sync_event, %{type: "account:finished", games_synced: g, achievements_synced: a}},
        socket
      ) do
    new_percent = min(socket.assigns.progress_percent + 10, 95)

    {:noreply,
     socket
     |> assign(:progress_percent, new_percent)
     |> assign(:message, "Conta sincronizada — jogos: #{g}, conquistas: #{a}")}
  end

  def handle_info({:sync_event, %{type: "account:failed", reason: _reason}}, socket) do
    {:noreply,
     socket
     |> assign(:status, :failed)
     |> assign(:title, "Sincronização interrompida")
     |> assign(:message, "Falha na sincronização da conta")
     |> assign(:progress, false)}
  end

  def handle_info(
        {:sync_event,
         %{
           type: "sync:finished",
           synced: synced,
           failed: failed,
           games_synced: gs,
           achievements_synced: as
         }},
        socket
      ) do
    {:noreply,
     socket
     |> assign(:status, :finished)
     |> assign(:title, "Sincronização concluída")
     |> assign(:progress_percent, 100)
     |> assign(
       :message,
       "Sincronização finalizada. #{synced} sucesso(s), #{failed} falha(s). ✓ #{gs} jogos, #{as} conquistas"
     )
     |> assign(:progress, false)}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp determine_status(running, failed, pending) do
    cond do
      running != [] -> :running
      failed != [] -> :failed
      pending != [] -> :idle
      true -> :none
    end
  end

  defp initial_count(:running, running, _failed, _pending), do: length(running)
  defp initial_count(:failed, _running, failed, _pending), do: length(failed)
  defp initial_count(:idle, _running, _failed, pending), do: length(pending)
  defp initial_count(_status, _running, _failed, _pending), do: 0

  defp initial_title(running, failed, pending) do
    cond do
      running != [] -> "Sincronização em andamento"
      failed != [] -> "Sincronização interrompida"
      pending != [] -> "Sincronização iniciando"
      true -> ""
    end
  end

  defp initial_message(running, failed, pending) do
    cond do
      running != [] -> "Estamos atualizando jogos e troféus agora."
      failed != [] -> "Algumas contas falharam e podem ser retomadas depois."
      pending != [] -> "Preparando atualização de jogos e troféus."
      true -> ""
    end
  end

  defp pending_sync_account?(account), do: account.sync_status in [nil, "idle"]

  @impl true
  def render(assigns) do
    ~H"""
    <div id="dashboard-sync-live">
      <button
        :if={@minimized and @status != :none}
        type="button"
        id="dashboard-sync-mini"
        class={["sidebar-icon dashboard-sync-mini", @status in [:running, :idle] && "is-running"]}
        phx-click="restore"
        title="Abrir sincronização"
        aria-label="Abrir sincronização"
      >
        <.icon
          name="hero-arrow-path"
          class={["size-5", @status in [:running, :idle] && "sync-spin-slow"]}
        />
      </button>

      <div
        :if={@status != :none and not @minimized}
        class="dashboard-sync-popup"
        id="dashboard-sync-popup"
      >
        <div class="popup-card" role="status" aria-live="polite">
          <div class={["popup-icon", @status in [:running, :idle] && "is-running"]}>
            <.icon
              name={popup_icon(@status)}
              class={["w-6 h-6 text-white", @status in [:running, :idle] && "sync-spin-slow"]}
            />
          </div>
          <div class="popup-content">
            <div class="popup-title">{@title}</div>
            <div class="popup-message">
              {@message}
              <span :if={@count} class="popup-count">{@count} conta(s)</span>
            </div>
            <div :if={@games_info != ""} class="popup-games-info">
              {String.slice(@games_info, 0..100)}{if String.length(@games_info) > 100, do: "..."}
            </div>

            <div :if={@progress} class="popup-progress">
              <div class="progress-bar" aria-hidden="true">
                <div class="progress-fill" style={"width: #{@progress_percent}%"}></div>
              </div>
              <div class="popup-progress-text">{@progress_percent}%</div>
              <div class="popup-actions">
                <button type="button" phx-click="minimize" class="btn-dismiss-sync">
                  Minimizar
                </button>
              </div>
            </div>

            <div :if={@status in [:finished, :failed]} class="popup-actions">
              <button type="button" phx-click="dismiss" class="btn-dismiss-sync">
                Fechar
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("dismiss", _params, socket) do
    socket =
      socket
      |> assign(:status, :none)
      |> assign(:minimized, false)
      |> push_event("dashboard_sync_reload", %{})

    {:noreply, socket}
  end

  def handle_event("minimize", _params, socket) do
    {:noreply, assign(socket, :minimized, true)}
  end

  def handle_event("restore", _params, socket) do
    {:noreply, assign(socket, :minimized, false)}
  end

  defp popup_icon(:finished), do: "hero-check"
  defp popup_icon(:failed), do: "hero-exclamation-triangle"
  defp popup_icon(_status), do: "hero-arrow-path"
end
