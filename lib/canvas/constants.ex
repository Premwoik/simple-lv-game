defmodule Canvas.Constants do
  def players_topic, do: "canvas:players"
  def monsters_topic, do: "canvas:monsters"
  def tick_topic, do: "canvas:monsters:tick"

  def monster_outfits, do: [{2329, 3}, {2250, 3}, {1432, 3}, {1501, 3}, {1447, 3}]
end
