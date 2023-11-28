defmodule Canvas.Monster.MoveRandom do
  alias Canvas.Monster.Move, as: MonsterMove
  alias Canvas.ObjectColisions
  alias Canvas.Board
  alias Canvas.MonstersLookup

  @behaviour MonsterMove

  @impl MonsterMove
  def move(monster, _details) do
    random_legal_move(monster, Board.get_board())
  end

  def random_legal_move(monster, board, legal_moves \\ ~w[up down left right]a)
  def random_legal_move(_monster, _borad, []), do: {:error, :no_legal_moves}

  def random_legal_move(monster, board, legal_moves) do
    %{tile_size: tile_size, width: width, height: height, obstacles: obstacles} = board

    move = Enum.random(legal_moves)

    new_monster =
      case move do
        :up -> %{monster | y: max(monster.y - tile_size, 0), orientation: 1}
        :down -> %{monster | y: min(monster.y + tile_size, height), orientation: 0}
        :left -> %{monster | x: max(monster.x - tile_size, 0), orientation: 3}
        :right -> %{monster | x: min(monster.x + tile_size, width), orientation: 2}
      end

    with false <- ObjectColisions.collide?(new_monster, obstacles),
         [] <- MonstersLookup.lookup_colliding_monsters(new_monster) do
      {:ok, new_monster}
    else
      _ ->
        random_legal_move(monster, board, List.delete(legal_moves, move))
    end
  end
end
