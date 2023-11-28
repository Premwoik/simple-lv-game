defmodule CanvasWeb.CanvasLive do
  use CanvasWeb, :live_view

  require Logger

  alias Phoenix.PubSub
  alias Phoenix.LiveView.Socket

  alias Canvas.Models.Player
  alias Canvas.Board
  alias Canvas.Constants
  alias Canvas.ObjectColisions
  alias Canvas.MonstersLookup
  alias Canvas.MonsterProcess
  alias Canvas.MonsterSupervisor

  # pixels
  @move_step 32
  # milliseconds
  @move_threshold 50

  # Move keys
  @move_left_keys ~w(a ArrowLeft)
  @move_right_keys ~w(d ArrowRight)
  @move_down_keys ~w(s ArrowDown)
  @move_up_keys ~w(w ArrowUp)
  @move_keys Enum.concat([@move_left_keys, @move_right_keys, @move_down_keys, @move_up_keys])

  # Topics
  @players_topic Constants.players_topic()
  @monster_topic Constants.monsters_topic()

  # JS Events
  @update_character_event "update-character"
  @delete_character_event "delete-character"

  @impl true
  def render(assigns) do
    ~H"""
    <.toolbar />
    <div
      id="game-canvas"
      class=""
      phx-hook="Canvas"
      phx-update="ignore"
      phx-keydown="button-press"
      phx-throttle="100"
    />
    """
  end

  def toolbar(assigns) do
    ~H"""
    <div class="py-2">
      <button type="button" class={btn_class()} phx-click="spawn-test-monsters">
        Spawn 10 monsters
      </button>
      <button type="button" class={btn_class()} phx-click="spawn-test-monster">
        Spawn monster
      </button>
      <button type="button" class={btn_class()} phx-click="spawn-following-monster">
        Spawn following monster
      </button>
      <button type="button" class={btn_class()} phx-click="kill-monsters">
        Kill monsters
      </button>
      <button type="button" class={btn_class()} phx-click="reset-player">
        Reset player
      </button>
    </div>
    """
  end

  defp btn_class do
    "bg-blue-600 border-blue-700 rounded-md py-2 px-4 text-sm text-white font-bold hover:bg-blue-700"
  end

  @impl true
  def mount(_params, _session, socket) do
    id = System.unique_integer([:positive, :monotonic])

    data = %{
      player: %Player{
        id: id,
        name: "Player #{id}",
        x: 32,
        y: 32,
        width: 30,
        height: 30,
        texture: 4117
      },
      move_timestamp: timestamp()
    }

    if connected?(socket) do
      :ok = PubSub.subscribe(Canvas.PubSub, @players_topic)
      :ok = PubSub.subscribe(Canvas.PubSub, @monster_topic)
      :ok = MonstersLookup.update_monster(self(), data.player)
    end

    {:ok, assign(socket, data)}
  end

  @impl true
  def terminate(reason, socket) do
    MonstersLookup.clear_monster(socket.assigns.player.id)
    broadcast_delete(socket)
    :ok = PubSub.unsubscribe(Canvas.PubSub, @players_topic)
    :ok = PubSub.unsubscribe(Canvas.PubSub, @monster_topic)

    reason
  end

  @impl true
  def handle_event("button-press", %{"key" => key}, socket) do
    {:noreply, handle_button_press(key, socket)}
  end

  def handle_event("canvas-loaded", _params, socket) do
    player = socket.assigns.player

    socket =
      MonstersLookup.lookup_area(0, 0, 800, 600)
      |> Enum.filter(fn [id | _] -> id != player.id end)
      |> Enum.reduce(socket, fn [_, x, y, _, _, details], acc_socket ->
        details = Map.merge(details, %{x: x, y: y})
        push_character_update(acc_socket, details)
      end)
      |> push_character_update(player)

    {:noreply, socket}
  end

  def handle_event("click-character", %{"id" => id}, socket) do
    with false <- id == socket.assigns.player.id,
         [{_, _, _, _, _, %{pid: pid}}] <- MonstersLookup.lookup(id) do
      MonsterProcess.stop(pid)
    end

    {:noreply, socket}
  end

  def handle_event("spawn-test-monsters", _params, socket) do
    MonsterSupervisor.spawn_test_monsters(10)
    {:noreply, socket}
  end

  def handle_event("spawn-test-monster", _params, socket) do
    MonsterSupervisor.spawn_test_monsters(1)
    {:noreply, socket}
  end

  def handle_event("spawn-following-monster", _params, socket) do
    MonsterSupervisor.spawn_test_monster_following_player(socket.assigns.player.id)
    {:noreply, socket}
  end

  def handle_event("kill-monsters", _params, socket) do
    MonsterSupervisor.kill_monsters()
    {:noreply, socket}
  end

  @impl true
  def handle_info({:update_player, player}, socket) do
    socket = push_character_update(socket, player)
    {:noreply, socket}
  end

  def handle_info({:delete_player, player_id}, socket) do
    socket = push_event(socket, @delete_character_event, %{id: player_id})
    {:noreply, socket}
  end

  def handle_info({:update_monster, monster}, socket) do
    socket = push_character_update(socket, monster)
    {:noreply, socket}
  end

  def handle_info({:delete_monster, monster_id}, socket) do
    socket = push_event(socket, @delete_character_event, %{id: monster_id})
    {:noreply, socket}
  end

  defp handle_button_press(key, socket) when key in @move_keys do
    now = timestamp()

    if now > socket.assigns.move_timestamp + @move_threshold do
      key
      |> handle_move(socket)
      |> handle_colisions(socket)
      |> assign(move_timestamp: now)
      |> push_character_update()
      |> broadcast_self_update()
    else
      socket
    end
  end

  defp handle_button_press(_key, socket) do
    socket
  end

  defp handle_colisions(new_socket, old_socket) do
    %{obstacles: obstacles} = Board.get_board()
    player = new_socket.assigns.player |> IO.inspect()

    with false <- ObjectColisions.collide?(player, obstacles),
         [] <- MonstersLookup.lookup_colliding_monsters(player) do
      :ok = MonstersLookup.update_monster(self(), player)
      new_socket
    else
      _ ->
        old_socket
    end
  end

  defp handle_move(key, socket) when key in @move_up_keys do
    old_player = socket.assigns.player
    player = %{old_player | y: old_player.y - @move_step, orientation: 1}
    assign(socket, :player, player)
  end

  defp handle_move(key, socket) when key in @move_down_keys do
    old_player = socket.assigns.player
    player = %{old_player | y: old_player.y + @move_step, orientation: 0}
    assign(socket, :player, player)
  end

  defp handle_move(key, socket) when key in @move_left_keys do
    old_player = socket.assigns.player
    player = %{old_player | x: old_player.x - @move_step, orientation: 3}
    assign(socket, :player, player)
  end

  defp handle_move(key, socket) when key in @move_right_keys do
    old_player = socket.assigns.player
    player = %{old_player | x: old_player.x + @move_step, orientation: 2}
    assign(socket, :player, player)
  end

  defp timestamp do
    System.os_time(:millisecond)
  end

  defp push_character_update(socket) do
    push_character_update(socket, socket.assigns.player)
  end

  defp push_character_update(socket, character) do
    character =
      character
      |> Map.take([:id, :x, :y, :name])
      |> Map.put(
        :texture,
        character.texture + character.orientation * character.texture_animation
      )
      |> Map.put(:type, get_character_type(character))
      |> IO.inspect()

    push_event(socket, @update_character_event, character)
  end

  defp get_character_type(%Player{}), do: "player"
  defp get_character_type(_), do: "monster"

  defp broadcast_self_update(%Socket{} = socket) do
    :ok = broadcast_self_update(socket.assigns.player)
    socket
  end

  defp broadcast_self_update(player) do
    :ok = PubSub.broadcast_from(Canvas.PubSub, self(), @players_topic, {:update_player, player})
  end

  defp broadcast_delete(socket) do
    player_id = socket.assigns.player.id
    :ok = PubSub.broadcast(Canvas.PubSub, @players_topic, {:delete_player, player_id})
  end
end
