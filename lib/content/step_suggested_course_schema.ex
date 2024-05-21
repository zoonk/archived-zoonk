defmodule Zoonk.Content.StepSuggestedCourse do
  @moduledoc """
  StepSuggestedCourse schema.

  Teachers can add suggested courses a user should take to either have a better understanding of the lesson or to be able to complete the lesson.
  This schema is used to store the suggested courses.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Zoonk.Content.Course
  alias Zoonk.Content.LessonStep

  @type t :: %__MODULE__{}

  schema "step_suggested_courses" do
    belongs_to :lesson_step, LessonStep
    belongs_to :course, Course

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(step_suggested_course, attrs) do
    step_suggested_course
    |> cast(attrs, [:lesson_step_id, :course_id])
    |> validate_required([:lesson_step_id, :course_id])
    |> unique_constraint([:lesson_step_id, :course_id])
  end
end
