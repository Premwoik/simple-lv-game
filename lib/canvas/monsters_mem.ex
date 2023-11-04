defmodule Canvas.MonstersMem do
  use GenServer

  @ets :monsters_pos_lookup

  def clear do
    GenServer.call(__MODULE__, :clear)
  end

  def lookup_monsters(monster) do
    lookup_monsters(monster.x, monster.y, monster.width, monster.height)
  end

  def lookup_monsters(x, y, width, height) do
    # Check if objects collide

    head = {:"$1", :"$2", :"$3", :"$4", :"$5"}

    guards = [
      {:<, x, {:+, :"$4", :"$2"}},
      {:>, x + width, :"$2"},
      {:<, y, {:+, :"$5", :"$3"}},
      {:>, y + height, :"$3"}
    ]

    select = [:"$$"]

    :ets.select(@ets, [{head, guards, select}])
  end

  def update_monster(pid, monster) do
    GenServer.cast(__MODULE__, {:update_monster, pid, monster})
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

  @impl true
  def handle_cast({:update_monster, pid, monster}, state) do
    :ets.insert(@ets, {pid, monster.x, monster.y, monster.width, monster.height})
    {:noreply, state}
  end

  def handle_call(:clear, _from, state) do
    :ets.delete_all_objects(@ets)
    {:reply, :ok, state}
  end
end

