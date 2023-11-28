defmodule Canvas.MonsterSupervisor do
  use DynamicSupervisor

  alias Canvas.MonsterProcess
  alias Canvas.Constants

  @monster_textures Constants.monster_outfits()

  def kill_monsters do
    for {:undefined, pid, :worker, [MonsterProcess]} <-
          DynamicSupervisor.which_children(__MODULE__) do
      MonsterProcess.stop(pid)
    end
  end

  def spawn_test_monsters(n \\ 1) do
    for _ <- 1..n do
      id = System.unique_integer([:positive, :monotonic])

      {texture, texture_animation} = Enum.random(@monster_textures)

      spawn_monster(
        %{
          id: id,
          name: "Test Monster #{id}",
          x: 32,
          y: 32,
          texture: texture,
          texture_animation: texture_animation
        },
        %{move_strategy: :target, target: %{x: 672, y: 256}}
      )
    end
  end

  def spawn_test_monster_following_player(player_id) do
    id = System.unique_integer([:positive, :monotonic])
    {texture, texture_animation} = Enum.random(@monster_textures)

    spawn_monster(
      %{
        id: id,
        name: "Test Monster #{id}",
        x: 32,
        y: 32,
        texture: texture,
        texture_animation: texture_animation
      },
      %{move_strategy: :follow, target: player_id}
    )
  end

  def spawn_monster(monster_opts, opts) do
    DynamicSupervisor.start_child(__MODULE__, %{
      id: MonsterProcess,
      start: {MonsterProcess, :start_link, [%{monster: monster_opts, opts: opts}]},
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
