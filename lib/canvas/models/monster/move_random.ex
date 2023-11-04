defmodule Canvas.Models.Monster.MoveRandom do
  alias Canvas.Models.Monster.Move, as: MonsterMove
  alias Canvas.ObjectColisions
  alias Canvas.Board

  @behaviour MonsterMove

  @impl MonsterMove
  def move(monster) do
    random_legal_move(monster, Board.get_board())
  end

  def random_legal_move(monster, board, legal_moves \\ ~w[up down left right]a)
  def random_legal_move(_monster, _borad, []), do: {:error, :no_legal_moves}

  def random_legal_move(monster, board, legal_moves) do
    %{tile_size: tile_size, width: width, height: height, obstacles: obstacles} = board

    move = Enum.random(legal_moves)

    new_monster =
      case move do
        :up -> Map.update!(monster, :y, &max(&1 - tile_size, 0))
        :down -> Map.update!(monster, :y, &min(&1 + tile_size, height))
        :left -> Map.update!(monster, :x, &max(&1 - tile_size, 0))
        :right -> Map.update!(monster, :x, &min(&1 + tile_size, width))
      end

    if ObjectColisions.collide?(new_monster, obstacles) do
      random_legal_move(monster, board, List.delete(legal_moves, move))
    else
      {:ok, new_monster}
    end
  end
end
