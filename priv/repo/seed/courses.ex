defmodule CourseSeed do
  @moduledoc false

  alias Uneebee.Content
  alias Uneebee.Content.Course
  alias Uneebee.Content.CourseUser
  alias Uneebee.Content.Lesson
  alias Uneebee.Content.LessonStep
  alias Uneebee.Organizations
  alias Uneebee.Repo

  @courses [
    %{
      name: "UneeBee for learners",
      description: "Learn how you can use UneeBee to learn new skills.",
      cover: "/uploads/seed/courses/uneebee_for_learners.avif",
      language: :en,
      level: :beginner,
      public?: true,
      published?: true,
      slug: "uneebee-for-learners",
      schools: ["uneebee"]
    },
    %{
      name: "Accounting processes",
      description: "Learn how to manage accounting processes.",
      cover: "/uploads/seed/courses/accounting_processes.avif",
      language: :en,
      level: :advanced,
      public?: false,
      published?: true,
      slug: "accounting-processes",
      schools: ["uneebee"]
    },
    %{
      name: "GDPR",
      description: "Learn how to manage GDPR.",
      cover: "/uploads/seed/courses/gdpr.avif",
      language: :en,
      level: :intermediate,
      public?: false,
      published?: false,
      slug: "gdpr",
      schools: ["uneebee"]
    },
    %{
      name: "Work at Apple",
      description: "Check if you have what it takes to work at Apple.",
      cover: nil,
      language: :en,
      level: :beginner,
      public?: true,
      published?: true,
      slug: "work-at-apple",
      schools: ["apple"]
    },
    %{
      name: "Work at Google",
      description: "Check if you have what it takes to work at Google.",
      cover: nil,
      language: :en,
      level: :beginner,
      public?: true,
      published?: true,
      slug: "work-at-google",
      schools: ["google"]
    }
  ]

  @lessons [
    %{
      cover: "/uploads/seed/courses/robot.png",
      description: "This is the example of the first lesson",
      name: "First lesson",
      order: 1,
      published?: true
    },
    %{
      cover: "/uploads/seed/courses/mars.png",
      description: "This is the example of the second lesson",
      name: "Second lesson",
      order: 2,
      published?: true
    },
    %{
      description: "This is the example of an unpublished.",
      name: "Third lesson",
      order: 3,
      published?: false
    }
  ]

  @lesson_steps [
    %{content: "This is the first step of the lesson.", order: 1},
    %{content: "We can also have images:", image: "/uploads/seed/courses/robot.png", order: 2},
    %{content: "Now should we ask users a question?", order: 3},
    %{content: "Great stuff! Lesson completed!", order: 4}
  ]

  @step_options [
    %{
      feedback: "Oops... Try again!",
      title: "Wrong answer",
      image: "/uploads/seed/courses/robot.png"
    },
    %{
      feedback: "Great job!",
      title: "Correct answer",
      image: "/uploads/seed/courses/mars.png",
      correct?: true
    }
  ]

  def seed do
    Enum.each(@courses, &handle_course/1)
  end

  defp handle_course(attrs) do
    Enum.each(attrs.schools, fn slug -> create_courses(attrs, slug) end)
  end

  defp create_courses(attrs, slug) do
    school = Organizations.get_school_by_slug!(slug)
    teachers = Organizations.list_school_users_by_role(school, :teacher)
    managers = Organizations.list_school_users_by_role(school, :manager)

    attrs = Map.put(attrs, :school_id, school.id)
    course = %Course{} |> Content.change_course(attrs) |> Repo.insert!()

    course_teacher = Enum.random(teachers)

    course_user_attrs = %{
      course_id: course.id,
      user_id: course_teacher.id,
      role: :teacher,
      approved?: true,
      approved_at: DateTime.utc_now(),
      approved_by_id: Enum.at(managers, 0).id
    }

    %CourseUser{} |> CourseUser.changeset(course_user_attrs) |> Repo.insert!()

    Enum.each(@lessons, fn lesson_attrs -> create_lessons(lesson_attrs, course) end)
  end

  defp create_lessons(attrs, course) do
    lesson_attrs = Map.put(attrs, :course_id, course.id)
    lesson = %Lesson{} |> Content.change_lesson(lesson_attrs) |> Repo.insert!()

    Enum.each(@lesson_steps, fn lesson_step_attrs ->
      create_lesson_steps(lesson_step_attrs, lesson)
    end)
  end

  defp create_lesson_steps(attrs, lesson) do
    lesson_step_attrs = Map.put(attrs, :lesson_id, lesson.id)
    lesson_step = %LessonStep{} |> Content.change_lesson_step(lesson_step_attrs) |> Repo.insert!()

    Enum.each(@step_options, fn step_option_attrs ->
      create_step_options(step_option_attrs, lesson_step)
    end)
  end

  defp create_step_options(attrs, lesson_step) do
    step_option_attrs = Map.put(attrs, :lesson_step_id, lesson_step.id)
    Content.create_step_option(step_option_attrs)
  end
end
