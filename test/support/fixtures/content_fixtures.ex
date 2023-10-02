defmodule Uneebee.Fixtures.Content do
  @moduledoc """
  This module defines test helpers for creating entities via the `Uneebee.Content` context.
  """

  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Organizations

  alias Uneebee.Content
  alias Uneebee.Content.Course
  alias Uneebee.Content.CourseUser
  alias Uneebee.Content.Lesson
  alias Uneebee.Content.UserLesson
  alias Uneebee.Repo
  alias UneebeeWeb.Plugs.Translate

  @doc """
  Get valid attributes for a course.
  """
  @spec valid_course_attributes(map()) :: map()
  def valid_course_attributes(attrs \\ %{}) do
    school = school_fixture()

    Enum.into(attrs, %{
      description: "random course description",
      public?: true,
      published?: true,
      language: hd(Translate.supported_locales()),
      name: "course title #{System.unique_integer()}",
      school_id: school.id,
      slug: "course-#{System.unique_integer()}"
    })
  end

  @doc """
  Get valid attributes for a lesson.
  """
  @spec valid_lesson_attributes(map()) :: map()
  def valid_lesson_attributes(attrs \\ %{}) do
    course = Map.get(attrs, :course, course_fixture())

    Enum.into(attrs, %{
      course_id: course.id,
      description: "random lesson description",
      kind: :story,
      name: "lesson title #{System.unique_integer()}",
      order: 1
    })
  end

  @doc """
  Get valid attributes for a lesson step.
  """
  @spec valid_lesson_step_attributes(map()) :: map()
  def valid_lesson_step_attributes(attrs \\ %{}) do
    lesson = Map.get(attrs, :lesson, lesson_fixture())

    Enum.into(attrs, %{
      content: "random lesson step content",
      kind: :text,
      lesson_id: lesson.id,
      order: 1
    })
  end

  @doc """
  Get valid attributes for a step option.
  """
  @spec valid_step_option_attributes(map()) :: map()
  def valid_step_option_attributes(attrs \\ %{}) do
    lesson_step = Map.get(attrs, :lesson_step, lesson_step_fixture())

    Enum.into(attrs, %{
      correct?: false,
      feedback: "random step option feedback",
      lesson_step_id: lesson_step.id,
      title: "title #{System.unique_integer([:positive, :monotonic])}"
    })
  end

  @doc """
  Generate a course.
  """
  @spec course_fixture(map()) :: Course.t()
  def course_fixture(attrs \\ %{}) do
    user = Map.get(attrs, :user, user_fixture())
    preload = Map.get(attrs, :preload, [])

    {:ok, course} = attrs |> valid_course_attributes() |> Content.create_course(user)
    Repo.preload(course, preload)
  end

  @doc """
  Generate a course user.
  """
  @spec course_user_fixture(map()) :: CourseUser.t()
  def course_user_fixture(attrs \\ %{}) do
    course = Map.get(attrs, :course, course_fixture())
    user = Map.get(attrs, :user, user_fixture())
    preload = Map.get(attrs, :preload, [])

    course_user_attrs =
      Enum.into(attrs, %{
        approved?: true,
        approved_at: DateTime.utc_now(),
        approved_by_id: user.id,
        role: :student
      })

    {:ok, course_user} = Content.create_course_user(course, user, course_user_attrs)
    Repo.preload(course_user, preload)
  end

  @doc """
  Generate a lesson.
  """
  @spec lesson_fixture(map()) :: Lesson.t()
  def lesson_fixture(attrs \\ %{}) do
    preload = Map.get(attrs, :preload, [])
    {:ok, lesson} = attrs |> valid_lesson_attributes() |> Content.create_lesson()
    Repo.preload(lesson, preload)
  end

  @doc """
  Generate a lesson step.
  """
  @spec lesson_step_fixture(map()) :: LessonStep.t()
  def lesson_step_fixture(attrs \\ %{}) do
    preload = Map.get(attrs, :preload, :options)
    {:ok, lesson_step} = attrs |> valid_lesson_step_attributes() |> Content.create_lesson_step()
    Repo.preload(lesson_step, preload)
  end

  @doc """
  Generate a step option.
  """
  @spec step_option_fixture(map()) :: StepOption.t()
  def step_option_fixture(attrs \\ %{}) do
    preload = Map.get(attrs, :preload, [])
    {:ok, step_option} = attrs |> valid_step_option_attributes() |> Content.create_step_option()
    Repo.preload(step_option, preload)
  end

  @doc """
  Generate multiple user lessons.

  This is useful when testing completed lessons by a user because we need to test
  a user has completed lessons for multiple days.
  """
  @spec generate_user_lesson(integer(), integer(), list()) :: :ok
  def generate_user_lesson(user_id, days, opts \\ []) do
    number_of_lessons = Keyword.get(opts, :number_of_lessons, 3)
    today = DateTime.utc_now()
    days_ago = DateTime.add(today, days, :day)
    lessons = Enum.map(1..number_of_lessons, fn _idx -> lesson_fixture() end)

    Enum.each(lessons, fn lesson ->
      Repo.insert!(%UserLesson{
        attempts: 1,
        correct: 1,
        total: 1,
        user_id: user_id,
        lesson_id: lesson.id,
        inserted_at: days_ago,
        updated_at: days_ago
      })
    end)
  end
end
