defmodule Canvas.MonsterSupervisor do
  use DynamicSupervisor

  alias Canvas.MonsterProcess

  def kill_monsters do
    for {:undefined, pid, :worker, [MonsterProcess]} <-
          DynamicSupervisor.which_children(__MODULE__) do
      MonsterProcess.stop(pid)
    end
  end

  def spawn_test_monsters(n \\ 1) do
    for _ <- 1..n do
      id = System.unique_integer([:positive, :monotonic])
      spawn_monster(%{id: id, name: "Test Monster #{id}"})
    end
  end

  def spawn_monster(opts) do
    DynamicSupervisor.start_child(__MODULE__, %{
      id: MonsterProcess,
      start: {MonsterProcess, :start_link, [opts]},
      restart: :temporary
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
