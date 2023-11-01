defmodule Canvas.Models.Player do
  use TypedEctoSchema

  import Ecto.Changeset

  typed_schema "players" do
    field :name, :string
    field :x, :integer, default: 0
    field :y, :integer, default: 0
    field :width, :integer, default: 32
    field :height, :integer, default: 32
  end

  def changeset(player, attrs) do
    player
    |> cast(attrs, [:name, :x, :y])
    |> validate_required([:name, :x, :y])
  end

  def new(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_changes()
  end
end
