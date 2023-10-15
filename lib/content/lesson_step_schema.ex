defmodule Uneebee.Content.LessonStep do
  @moduledoc """
  LessonStep schema.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Uneebee.Content.Lesson
  alias Uneebee.Content.StepOption

  @type t :: %__MODULE__{}

  schema "lesson_steps" do
    field :content, :string
    field :image, :string
    field :order, :integer

    belongs_to :lesson, Lesson
    has_many :options, StepOption

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(lesson_step, attrs) do
    lesson_step
    |> cast(attrs, [:content, :image, :lesson_id, :order])
    |> validate_required([:content, :lesson_id, :order])
    |> validate_length(:content, max: 600)
  end
end
