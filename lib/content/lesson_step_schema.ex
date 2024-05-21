defmodule Zoonk.Content.LessonStep do
  @moduledoc """
  LessonStep schema.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Zoonk.Content.CourseUtils
  alias Zoonk.Content.Lesson
  alias Zoonk.Content.StepOption
  alias Zoonk.Content.StepSuggestedCourse

  @type t :: %__MODULE__{}

  schema "lesson_steps" do
    field :content, :string
    field :image, :string
    field :kind, Ecto.Enum, values: [:readonly, :quiz, :open_ended], default: :readonly
    field :order, :integer

    belongs_to :lesson, Lesson
    has_many :options, StepOption
    has_many :suggested_courses, StepSuggestedCourse

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(lesson_step, attrs) do
    lesson_step
    |> cast(attrs, [:content, :image, :kind, :lesson_id, :order])
    |> validate_required([:content, :kind, :lesson_id, :order])
    |> validate_length(:content, max: CourseUtils.max_length(:step_content))
  end
end
