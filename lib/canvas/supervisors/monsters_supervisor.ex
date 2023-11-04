defmodule Canvas.MonstersSupervisor do
  use DynamicSupervisor

  alias Canvas.Models.Monster
  alias Canvas.MonstersMem

  def stop do
    DynamicSupervisor.stop(__MODULE__)
    MonstersMem.clear()
  end

  def get_monsters(caller_pid) do
    for {:undefined, pid, :worker, [Monster]} <- DynamicSupervisor.which_children(__MODULE__),
        pid != caller_pid do
      Monster.get_monster(pid)
    end
  end

  def spawn_test_monsters(n \\ 1) do
    for i <- 1..n do
      spawn_monster(%{name: "Test Monster #{i}"})
    end
  end

  def spawn_monster(opts) do
    DynamicSupervisor.start_child(__MODULE__, %{
      id: Monster,
      start: {Monster, :start_link, [opts]}
    })
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  def start_link(opts \\ []) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
