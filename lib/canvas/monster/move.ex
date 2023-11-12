defmodule Canvas.Monster.Move do
  alias Cavnas.Monster
  alias Canvas.Monster.MoveRandom
  alias Canvas.Monster.MoveTarget
  alias Canvas.Monster.MoveFollow

  @callback(
    move(Monster.t(), map()) :: {:ok, Monster.t()},
    {:error, :no_legal_moves | :on_target}
  )

  def move(monster, details \\ %{}, strategy)
  def move(monster, details, :random), do: MoveRandom.move(monster, details)
  def move(monster, details, :target), do: MoveTarget.move(monster, details)
  def move(monster, details, :follow), do: MoveFollow.move(monster, details)
end
