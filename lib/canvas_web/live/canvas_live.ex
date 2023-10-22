defmodule CanvasWeb.CanvasLive do
  use CanvasWeb, :live_view

  require Logger

  alias Phoenix.PubSub

  # 10 pixels
  @move_step 10
  # 100 milliseconds
  @move_threshold 50

  # Move keys
  @move_left_keys ~w(a ArrowLeft)
  @move_right_keys ~w(d ArrowRight)
  @move_down_keys ~w(s ArrowDown)
  @move_up_keys ~w(w ArrowUp)
  @move_keys Enum.concat([@move_left_keys, @move_right_keys, @move_down_keys, @move_up_keys])

  # Topics
  @players_topic "canvas:players"

  # JS Events
  @position_update_event "player-position"
  @close_players_position_update_event "close-players-position"

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Hello canvas!</h1>
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
      player_name: Ecto.UUID.generate(),
      player_position: %{x: 0, y: 0},
      move_timestamp: timestamp()
    }

    {:ok, socket |> assign(data) |> broadcast_player_position()}
  end

  @impl true
  def handle_event("button-press", %{"key" => key}, socket) do
    {:noreply, handle_button_press(key, socket)}
  end

  @impl true
  def handle_info({:player_position, data}, socket) do
    socket =
      if data.name == socket.assigns.player_name do
        socket
      else
        IO.puts("Player position: #{inspect(data)}")

        socket
        |> assign(players: Map.put(socket.assigns.players, data.name, data))
        |> push_event(@close_players_position_update_event, data)
      end

    {:noreply, socket}
  end

  def handle_button_press(key, socket) when key in @move_keys do
    now = timestamp()

    if now > socket.assigns.move_timestamp + @move_threshold do
      key
      |> handle_move(socket)
      |> assign(move_timestamp: now)
      |> broadcast_player_position()
    else
      socket
    end
  end

  def handle_button_press(_key, socket) do
    socket
  end

  def handle_move(key, socket) when key in @move_up_keys do
    old_position = socket.assigns.player_position
    position = %{old_position | y: old_position.y - @move_step}

    socket
    |> assign(:player_position, position)
    |> push_event(@position_update_event, position)
  end

  def handle_move(key, socket) when key in @move_down_keys do
    old_position = socket.assigns.player_position
    position = %{old_position | y: old_position.y + @move_step}

    socket
    |> assign(:player_position, position)
    |> push_event(@position_update_event, position)
  end

  def handle_move(key, socket) when key in @move_left_keys do
    old_position = socket.assigns.player_position
    position = %{old_position | x: old_position.x - @move_step}

    socket
    |> assign(:player_position, position)
    |> push_event(@position_update_event, position)
  end

  def handle_move(key, socket) when key in @move_right_keys do
    old_position = socket.assigns.player_position
    position = %{old_position | x: old_position.x + @move_step}

    socket
    |> assign(:player_position, position)
    |> push_event(@position_update_event, position)
  end

  def timestamp do
    System.os_time(:millisecond)
  end

  def broadcast_player_position(socket) do
    assigns = socket.assigns

    data = %{
      x: assigns.player_position.x,
      y: assigns.player_position.y,
      name: assigns.player_name
    }

    :ok = PubSub.broadcast(Canvas.PubSub, @players_topic, {:player_position, data})

    socket
  end
end
