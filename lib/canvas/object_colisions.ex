defmodule Canvas.ObjectColisions do
  def collide?(player, objects) when is_list(objects) do
    Enum.any?(objects, fn object -> collide?(player, object) end)
  end

  def collide?(player, object) do
    player.x <= object["x"] + object["width"] && player.x + player.width >= object["x"] &&
      player.y <= object["y"] + object["height"] && player.y + player.height >= object["y"]
  end
end
