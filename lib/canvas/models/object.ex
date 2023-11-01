defmodule Canvas.Models.Object do
  import Ecto.Changeset

  use TypedEctoSchema

  @required_fields ~w[id name x y]a
  @optional_fields ~w[type rotation visible width height]a

  typed_embedded_schema do
    field :name, :string
    field :type, :string
    field :rotation, :integer, default: 0
    field :visible, :boolean, default: true
    field :x, :integer
    field :y, :integer
    field :width, :integer, default: 32
    field :height, :integer, default: 32
  end

  def changeset(%__MODULE__{} = object, attrs) do
    object
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
  end

  def new(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_changes()
  end
end
