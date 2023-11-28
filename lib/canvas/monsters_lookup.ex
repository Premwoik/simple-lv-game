defmodule Canvas.MonstersLookup do
  use GenServer

  @ets :monsters_pos_lookup

  @type monster() :: %{
          x: non_neg_integer(),
          y: non_neg_integer(),
          width: non_neg_integer(),
          height: non_neg_integer(),
          name: String.t(),
          orientation: 0..3,
          type: :monster | :player
        }

  @type row() ::
          {pid(), x :: non_neg_integer(), y :: non_neg_integer(), width :: non_neg_integer(),
           height :: non_neg_integer(), name :: String.t()}

  def clear do
    GenServer.call(__MODULE__, :clear)
  end

  def lookup(id) do
    :ets.lookup(@ets, id)
  end

  @spec lookup_colliding_monsters(monster()) :: [row()]
  def lookup_colliding_monsters(monster) do
    lookup_area(monster.x, monster.y, monster.width, monster.height)
  end

  def lookup_area(x, y, width, height) do
    # Check if objects collide

    head = {:"$1", :"$2", :"$3", :"$4", :"$5", :"$6"}

    guards = [
      {:<, x, {:+, :"$4", :"$2"}},
      {:>, x + width, :"$2"},
      {:<, y, {:+, :"$5", :"$3"}},
      {:>, y + height, :"$3"}
    ]

    select = [:"$$"]

    :ets.select(@ets, [{head, guards, select}])
  end

  @spec update_monster(pid(), monster()) :: :ok
  def update_monster(pid, monster) do
    GenServer.cast(__MODULE__, {:update_monster, pid, monster})
  end

  @spec clear_monster(integer()) :: :ok
  def clear_monster(id) do
    GenServer.cast(__MODULE__, {:clear_monster, id})
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker
    }
  end

  @impl GenServer
  def init(_opts) do
    :ets.new(@ets, [:set, :named_table])
    {:ok, %{}}
  end

  @impl GenServer
  def handle_cast({:update_monster, pid, %{id: id} = monster}, state) do
    details = monster |> Map.take([:id, :name, :texture]) |> Map.put(:pid, pid)
    :ets.insert(@ets, {id, monster.x, monster.y, monster.width, monster.height, details})
    {:noreply, state}
  end

  def handle_cast({:clear_monster, id}, state) do
    true = :ets.delete(@ets, id)
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:clear, _from, state) do
    :ets.delete_all_objects(@ets)
    {:reply, :ok, state}
  end
end
