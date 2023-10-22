defmodule CanvasWeb.CanvasLive do
  use CanvasWeb, :live_view

  require Logger

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
    data = %{
      move_timestamp: timestamp()
    }

    {:ok, assign(socket, data)}
  end

  @move_keys ~w(w a s d)
  @move_threshold 100

  @impl true
  def handle_event("button-press", %{"key" => key}, socket) do
    {:noreply, handle_button_press(key, socket)}
  end

  def handle_button_press(key, socket) when key in @move_keys do
    now = timestamp()

    if now > socket.assigns.move_timestamp + @move_threshold do
      key
      |> handle_move(socket)
      |> assign(move_timestamp: now)
    else
      socket
    end
  end

  def handle_button_press(_key, socket) do
    socket
  end

  def handle_move("w", socket) do
    push_event(socket, "move-up", %{})
  end

  def handle_move("s", socket) do
    push_event(socket, "move-down", %{})
  end

  def handle_move("a", socket) do
    push_event(socket, "move-left", %{})
  end

  def handle_move("d", socket) do
    push_event(socket, "move-right", %{})
  end

  def timestamp do
    System.os_time(:millisecond)
  end
end
