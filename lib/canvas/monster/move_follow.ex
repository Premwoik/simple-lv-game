defmodule Canvas.Monster.MoveFollow do
  require Logger

  alias Canvas.Monster.Move, as: MonsterMove
  alias Canvas.Monster.MoveTarget
  alias Canvas.MonstersLookup

  @behaviour MonsterMove

  @impl MonsterMove
  def move(monster, details) do
    [{_, x, y, _, _, _}] = MonstersLookup.lookup(details.target)
    MoveTarget.move(monster, %{details | target: %{x: x, y: y}})
  end
end
