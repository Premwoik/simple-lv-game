defmodule Canvas.Models.Monster do
  use TypedEctoSchema

  alias Canvas.Board
  alias Canvas.Constants
  alias Canvas.ObjectColisions
  alias Phoenix.PubSub

  @monster_topic Constants.monsters_topic()

  @behaviour GenServer

  typed_embedded_schema do
    field :name, :string
    field :x, :integer, default: 0
    field :y, :integer, default: 0
    field :width, :integer, default: 30
    field :height, :integer, default: 30
  end

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  @impl GenServer
  def init(init_data) do
    next_random_move()
    {:ok, %{monster: struct(__MODULE__, init_data)}}
  end

  @impl GenServer
  def handle_info(:random_move, %{monster: monster} = state) do
    %{tile_size: tile_size, width: width, height: height, obstacles: obstacles} =
      Board.get_board()

    new_monster =
      case :rand.uniform(4) do
        1 -> Map.update!(monster, :y, &max(&1 - tile_size, 0))
        2 -> Map.update!(monster, :y, &min(&1 + tile_size, height))
        3 -> Map.update!(monster, :x, &max(&1 - tile_size, 0))
        4 -> Map.update!(monster, :x, &min(&1 + tile_size, width))
      end

    if ObjectColisions.collide?(new_monster, obstacles) do
      # Illegal move, try again
      send(self(), :random_move)
      {:noreply, state}
    else
      :ok = broadcast_monster_position(new_monster)
      next_random_move()
      {:noreply, %{state | monster: new_monster}}
    end
  end

  def next_random_move do
    Process.send_after(self(), :random_move, 1000)
  end

  def broadcast_monster_position(monster) do
    :ok = PubSub.broadcast(Canvas.PubSub, @monster_topic, {:monster_position, monster})
  end
end
