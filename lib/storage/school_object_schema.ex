defmodule Zoonk.Storage.SchoolObject do
  @moduledoc """
  `SchoolObject` schema.

  School objects are the files uploaded to the school. They can be images, videos, audio, etc.

  Tracking school objects allows them to manage their storage as well as easily remove unused files.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Zoonk.Content.Course
  alias Zoonk.Content.Lesson
  alias Zoonk.Content.LessonStep
  alias Zoonk.Content.StepOption
  alias Zoonk.Organizations.School

  @type t :: %__MODULE__{}

  schema "school_objects" do
    field :key, :string
    field :content_type, :string
    field :size_kb, :integer

    belongs_to :school, School
    belongs_to :course, Course
    belongs_to :lesson, Lesson
    belongs_to :lesson_step, LessonStep
    belongs_to :step_option, StepOption

    timestamps(type: :utc_datetime)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(schema, params) do
    schema
    |> cast(params, [:key, :content_type, :size_kb, :school_id, :course_id, :lesson_id, :lesson_step_id, :step_option_id])
    |> validate_required([:key, :content_type, :size_kb, :school_id])
    |> unique_constraint([:key])
  end
end
