defmodule CanvasWeb.CanvasLive do
  use CanvasWeb, :live_view

  require Logger

  alias Phoenix.PubSub

  alias Canvas.Player

  # pixels
  @move_step 20
  # milliseconds
  @move_threshold 50
  # milliseconds
  @update_interval 500

  # Move keys
  @move_left_keys ~w(a ArrowLeft)
  @move_right_keys ~w(d ArrowRight)
  @move_down_keys ~w(s ArrowDown)
  @move_up_keys ~w(w ArrowUp)
  @move_keys Enum.concat([@move_left_keys, @move_right_keys, @move_down_keys, @move_up_keys])

  # Topics
  @players_topic "canvas:players"

  # JS Events
  @position_update_event "update-player-position"
  @delete_player_event "delete-player"

  @impl true
  def render(assigns) do
    ~H"""
    <.focus_wrap id="game">
      <div
        id="game-canvas"
        phx-hook="Canvas"
        phx-update="ignore"
        phx-keydown="button-press"
        phx-throttle="100"
      />
    </.focus_wrap>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    :ok = PubSub.subscribe(Canvas.PubSub, @players_topic)

    data = %{
      players: %{},
      player: %Player{name: Ecto.UUID.generate()},
      move_timestamp: timestamp(),
      update_timer: make_ref()
    }

    {:ok, socket |> assign(data) |> set_position_update_timer()}
  end

  @impl true
  def terminate(reason, socket) do
    broadcast_delete(socket)
    :ok = PubSub.unsubscribe(Canvas.PubSub, @players_topic)

    reason
  end

  @impl true
  def handle_event("button-press", %{"key" => key}, socket) do
    {:noreply, handle_button_press(key, socket)}
  end

  @impl true
  def handle_info({:player_position, data}, socket) do
    socket =
      if data.name == socket.assigns.player.name do
        socket
      else
        player = Player.new(data)

        socket
        |> assign(players: Map.put(socket.assigns.players, player.name, player))
        |> push_player_position_update(player, broadcast: false)
      end

    {:noreply, socket}
  end

  def handle_info({:delete_player, data}, socket) do
    socket =
      socket
      |> assign(players: Map.delete(socket.assigns.players, data.name))
      |> push_event(@delete_player_event, data)

    {:noreply, socket}
  end

  def handle_info(:update_player_position, socket) do
    socket =
      socket
      |> push_player_position_update(socket.assigns.player)
      |> set_position_update_timer()

    {:noreply, socket}
  end

  def handle_button_press(key, socket) when key in @move_keys do
    now = timestamp()

    if now > socket.assigns.move_timestamp + @move_threshold do
      Process.cancel_timer(socket.assigns.update_timer)

      key
      |> handle_move(socket)
      |> assign(move_timestamp: now)
      |> push_player_position_update()
      |> set_position_update_timer()
    else
      socket
    end
  end

  def handle_button_press(_key, socket) do
    socket
  end

  def handle_move(key, socket) when key in @move_up_keys do
    old_player = socket.assigns.player
    player = %{old_player | y: old_player.y - @move_step}
    assign(socket, :player, player)
  end

  def handle_move(key, socket) when key in @move_down_keys do
    old_player = socket.assigns.player
    player = %{old_player | y: old_player.y + @move_step}
    assign(socket, :player, player)
  end

  def handle_move(key, socket) when key in @move_left_keys do
    old_player = socket.assigns.player
    player = %{old_player | x: old_player.x - @move_step}
    assign(socket, :player, player)
  end

  def handle_move(key, socket) when key in @move_right_keys do
    old_player = socket.assigns.player
    player = %{old_player | x: old_player.x + @move_step}
    assign(socket, :player, player)
  end

  def timestamp do
    System.os_time(:millisecond)
  end

  def push_player_position_update(socket) do
    push_player_position_update(socket, socket.assigns.player)
  end

  def push_player_position_update(socket, %Player{} = player, opts \\ []) do
    position = Map.take(player, [:x, :y, :name])

    if Keyword.get(opts, :broadcast, true) do
      :ok = PubSub.broadcast(Canvas.PubSub, @players_topic, {:player_position, position})
    end

    push_event(socket, @position_update_event, position)
  end

  def broadcast_delete(socket) do
    position = Map.take(socket.assigns.player, [:x, :y, :name])
    :ok = PubSub.broadcast(Canvas.PubSub, @players_topic, {:delete_player, position})
  end

  def set_position_update_timer(socket) do
    Process.cancel_timer(socket.assigns.update_timer)

    assign(socket,
      update_timer: Process.send_after(self(), :update_player_position, @update_interval)
    )
  end
end
