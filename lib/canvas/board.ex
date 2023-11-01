defmodule Canvas.Board do
  # use TypedEctoSchema
  #
  # typed_embedded_schema do
  #   has_many :monsters, Canvas.Models.Object
  #   has_many :players, Canvas.Models.Object
  #   has_many :obstacles, Canvas.Models.Object
  #   has_many :points, Canvas.Models.Object
  # end

  def get_board do
    :persistent_term.get(:board)
  end

  def load_map(path) do
    with {:ok, binary} <- File.read(path),
         {:ok, json} <- Jason.decode(binary) do
      obstacles = get_in_list(json["layers"], "obstacles")["objects"]
      # Enum.filter(json["layers"], fn layer -> layer["type"] == "objectgroup" end)
      #
      #
      #   %{data: data, name: layer["name"], type: layer["type"]}
      # end)

      {:ok, %{obstacles: obstacles, width: 700, height: 500, tile_size: 32}}
    end
  end

  def get_in_list(list, name) do
    Enum.find(list, fn item -> item["name"] == name end)
  end
end
