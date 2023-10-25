defmodule Canvas.Board do
  use TypedEctoSchema

  typed_embedded_schema do
  end

  def load_chunk(path) do
    with {:ok, binary} <- File.read(path),
         {:ok, json} <- Jason.decode(binary) do
      data =
        Enum.map(json["layers"], fn layer ->
          # data =
          #   if data = layer["data"] do
          #     Base.decode64!(data)
          #   end

          %{data: layer["data"], name: layer["name"], type: layer["type"]}
        end)

      {:ok, data}
    end
  end
end
