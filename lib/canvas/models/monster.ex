defmodule Canvas.Models.Monster do
  use GenStateMachine
  use TypedEctoSchema

  alias Canvas.Constants
  alias Phoenix.PubSub
  alias Canvas.Models.Monster.Move, as: MonsterMove
  alias Canvas.MonstersMem

  @monster_tick 200
  @monster_topic Constants.monsters_topic()
  @players_topic Constants.players_topic()

  typed_embedded_schema do
    field :name, :string
    field :x, :integer, default: 0
    field :y, :integer, default: 0
    field :width, :integer, default: 30
    field :height, :integer, default: 30
    field :sprite, :string, default: "/textures/monster"
  end

  def start_link(init_arg) do
    GenStateMachine.start_link(__MODULE__, init_arg)
  end

  def get_monster(pid) do
    GenStateMachine.call(pid, :get_monster)
  end

  @impl GenStateMachine
  def init(init_data) do
    :ok = PubSub.subscribe(Canvas.PubSub, @players_topic)
    :ok = PubSub.subscribe(Canvas.PubSub, @monster_topic)

    data =
      %{tick_timer: make_ref(), monster: struct(__MODULE__, init_data)}
      |> next_monster_tick()

    {:ok, :alive, data}
  end

  @impl GenStateMachine
  def terminate(reason, _state, _data) do
    :ok = PubSub.unsubscribe(Canvas.PubSub, @players_topic)
    :ok = PubSub.subscribe(Canvas.PubSub, @monster_topic)
    reason
  end

  @impl GenStateMachine
  def handle_event({:call, pid}, :get_monster, _state, data) do
    {:keep_state, data, [{:reply, pid, data.monster}]}
  end

  def handle_event(:info, :tick, _state, data) do
    {:keep_state, do_monster_move(data)}
  end

  def handle_event(:info, _msg, _state, data) do
    {:keep_state, data}
  end

  def do_monster_move(%{monster: monster} = data) do
    new_monster = monster |> MonsterMove.move(:random) |> Result.with_default(monster)

    if [] == MonstersMem.lookup_monsters(new_monster) do
      :ok = MonstersMem.update_monster(self(), new_monster)
      :ok = broadcast_monster_position(new_monster)
      %{data | monster: new_monster}
    else
      data
    end
    |> next_monster_tick()
  end

  def next_monster_tick(%{tick_timer: tick_timer} = data) do
    Process.cancel_timer(tick_timer)
    tick_timer = Process.send_after(self(), :tick, @monster_tick)
    %{data | tick_timer: tick_timer}
  end

  def broadcast_monster_position(monster) do
    :ok = PubSub.broadcast(Canvas.PubSub, @monster_topic, {:monster_position, monster})
  end
end
