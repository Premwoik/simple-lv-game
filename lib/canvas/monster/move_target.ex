defmodule Canvas.Monster.MoveTarget do
  require Logger

  alias Canvas.Monster.Move, as: MonsterMove
  alias Canvas.ObjectColisions
  alias Canvas.Board
  alias Canvas.MonstersLookup

  @behaviour MonsterMove

  @tile_size 32

  @impl MonsterMove
  def move(monster, details) do
    move_toward_target(monster, details)
  end

  def move_toward_target(monster, details) when details == %{} do
    Logger.error(%{
      description: "No target specified for move target strategy",
      monster: monster,
      details: details,
      strategy: __MODULE__
    })

    {:error, :no_legal_moves}
  end

  def move_toward_target(%{x: x, y: y}, %{target: %{x: x, y: y}}) do
    {:error, :on_target}
  end

  def move_toward_target(monster, details) do
    %{tile_size: tile_size, width: width, height: height, obstacles: obstacles} =
      Board.get_board()

    %{target: target, history: history} = details
    neighborhood = get_neighborhood_monsters(monster)

    [
      Map.update!(monster, :y, &max(&1 - tile_size, 0)),
      Map.update!(monster, :y, &min(&1 + tile_size, height)),
      Map.update!(monster, :x, &max(&1 - tile_size, 0)),
      Map.update!(monster, :x, &min(&1 + tile_size, width))
    ]
    |> Enum.filter(&allowed_move?(&1, obstacles, neighborhood, history))
    |> Enum.min_by(&distance_to_target(&1, target), fn -> nil end)
    |> case do
      nil -> {:error, :no_legal_moves}
      %{} = monster -> {:ok, monster}
    end
  end

  defp allowed_move?(monster, obstacles, neighborhood, history) do
    false == ObjectColisions.collide?(monster, obstacles) &&
      not_in(monster, neighborhood) && not_in(monster, history)
  end

  defp distance_to_target(monster, target) do
    x = monster.x - target.x
    y = monster.y - target.y
    :math.sqrt(x ** 2 + y ** 2)
  end

  defp get_neighborhood_monsters(this) do
    x = this.x - @tile_size
    y = this.y - @tile_size
    width = x + @tile_size * 3
    height = y + @tile_size * 3

    MonstersLookup.lookup_area(x, y, width, height)
    |> Enum.map(fn [id, x, y, w, h, _details] ->
      %{id: id, x: x, y: y, width: w, height: h}
    end)
    |> Enum.filter(&(&1.id != this.id))
  end

  defp not_in(monster, list), do: not Enum.any?(list, &(&1.x == monster.x and &1.y == monster.y))
end
