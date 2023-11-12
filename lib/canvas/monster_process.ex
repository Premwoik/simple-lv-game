defmodule Canvas.MonsterProcess do
  use GenStateMachine
  use TypedEctoSchema

  alias Canvas.Constants
  alias Phoenix.PubSub
  alias Canvas.Monster.Move, as: MonsterMove
  alias Canvas.MonstersLookup

  @monster_tick 300
  @monster_topic Constants.monsters_topic()
  @history_size 3

  typed_embedded_schema do
    field :name, :string
    field :x, :integer, default: 0
    field :y, :integer, default: 0
    field :width, :integer, default: 30
    field :height, :integer, default: 30
    field :texture, :integer, default: 1
  end

  def start_link(init_arg) do
    GenStateMachine.start_link(__MODULE__, init_arg)
  end

  def stop(pid) do
    GenStateMachine.stop(pid)
  end

  def get_monster(pid) do
    GenStateMachine.call(pid, :get_monster)
  end

  @impl GenStateMachine
  def init(%{monster: monster, opts: opts}) do
    data =
      %{
        tick_timer: make_ref(),
        monster: struct(__MODULE__, monster),
        history: [],
        move_strategy: Map.get(opts, :move_strategy, :random),
        target: Map.get(opts, :target)
      }
      |> next_monster_tick()

    {:ok, :alive, data}
  end

  @impl GenStateMachine
  def terminate(reason, _state, data) do
    MonstersLookup.clear_monster(data.monster.id)
    :ok = broadcast_monster_delete(data.monster)
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

  def do_monster_move(%{monster: monster, history: history, move_strategy: strategy} = data) do
    case MonsterMove.move(monster, prepare_strategy_details(data), strategy) do
      {:ok, new_monster} ->
        :ok = MonstersLookup.update_monster(self(), new_monster)
        :ok = broadcast_monster_update(new_monster)
        %{data | monster: new_monster, history: update_history(history, new_monster)}

      {:error, :no_legal_moves} ->
        # Clear the history when no legal moves
        %{data | history: []}

      {:error, :on_target} ->
        data
    end
    |> next_monster_tick()
  end

  def next_monster_tick(%{tick_timer: tick_timer} = data) do
    Process.cancel_timer(tick_timer)
    tick_timer = Process.send_after(self(), :tick, @monster_tick)
    %{data | tick_timer: tick_timer}
  end

  def broadcast_monster_update(monster) do
    :ok = PubSub.broadcast(Canvas.PubSub, @monster_topic, {:update_monster, monster})
  end

  def broadcast_monster_delete(monster) do
    :ok = PubSub.broadcast(Canvas.PubSub, @monster_topic, {:delete_monster, monster.id})
  end

  defp prepare_strategy_details(%{move_strategy: strategy, history: history, target: target})
       when strategy in [:target, :follow] do
    %{target: target, history: history}
  end

  defp prepare_strategy_details(%{move_strategy: :random}) do
    %{}
  end

  defp update_history(history, new) do
    new = Map.take(new, [:x, :y])
    Enum.take([new | history], @history_size)
  end
end
