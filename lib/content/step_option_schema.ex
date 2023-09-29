defmodule Uneebee.Content.StepOption do
  @moduledoc """
  StepOption schema.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Uneebee.Content.LessonStep

  @type t :: %__MODULE__{}

  schema "step_options" do
    field :correct?, :boolean, default: false
    field :feedback, :string
    field :image, :string
    field :title, :string

    belongs_to :lesson_step, LessonStep

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(step_option, attrs) do
    step_option
    |> cast(attrs, [:correct?, :feedback, :image, :title, :lesson_step_id])
    |> validate_required([:correct?, :title, :lesson_step_id])
    |> validate_length(:feedback, max: 280)
    |> validate_length(:title, max: 80)
  end
end
