defmodule Canvas.Monster.Move do
  alias Cavnas.Monster
  alias Canvas.Monster.MoveRandom
  @callback(move(Monster.t()) :: {:ok, Monster.t()}, {:error, :no_legal_moves})

  def move(monster, strategy)
  def move(monster, :random), do: MoveRandom.move(monster)
end
