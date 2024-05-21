defmodule CourseSeed do
  @moduledoc false

  alias Zoonk.Organizations.School
  alias Zoonk.Content
  alias Zoonk.Content.Course
  alias Zoonk.Content.CourseUser
  alias Zoonk.Content.Lesson
  alias Zoonk.Content.LessonStep
  alias Zoonk.Organizations
  alias Zoonk.Repo

  @courses [
    %{
      name: "Zoonk for learners",
      description: "Learn how you can use Zoonk to learn new skills.",
      cover: "/uploads/seed/courses/zoonk_for_learners.avif",
      language: :en,
      level: :beginner,
      public?: true,
      published?: true,
      slug: "zoonk-for-learners",
      schools: ["zoonk"]
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
      schools: ["zoonk"]
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
      schools: ["zoonk"]
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
    %{content: "This is the first step of the lesson.", kind: :quiz, order: 1},
    %{
      content: "We can also have images:",
      kind: :quiz,
      image: "/uploads/seed/courses/robot.png",
      order: 2
    },
    %{content: "Now should we ask users a question?", kind: :quiz, order: 3},
    %{content: "Great stuff! Lesson completed!", kind: :quiz, order: 4}
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

  def seed(args \\ %{}) do
    multiple? = Map.get(args, :multiple?, false)
    courses = generate_course_attrs(multiple?)

    Enum.each(courses, fn course -> handle_course(course, multiple?) end)
  end

  defp handle_course(attrs, multiple?) do
    Enum.each(attrs.schools, fn slug -> create_courses(attrs, slug, multiple?) end)
  end

  defp generate_course_attrs(false), do: @courses
  defp generate_course_attrs(true), do: generate_course_attrs()

  defp generate_course_attrs() do
    random_courses =
      Enum.map(1..80, fn idx ->
        %{
          name: "Course #{idx}",
          description: "This is the example of the course #{idx}",
          cover: nil,
          language: :en,
          level: :beginner,
          public?: true,
          published?: true,
          slug: "course-#{idx}",
          schools: ["apple"]
        }
      end)

    @courses ++ random_courses
  end

  defp create_courses(attrs, slug, multiple?) do
    school = Repo.get_by(School, slug: slug)
    limit = if multiple?, do: 200, else: 3

    if school do
      teachers = Organizations.list_school_users(school.id, role: :teacher)
      managers = Organizations.list_school_users(school.id, role: :manager)
      students = Organizations.list_school_users(school.id, role: :student, limit: limit)

      attrs = Map.put(attrs, :school_id, school.id)
      course = %Course{} |> Content.change_course(attrs) |> Repo.insert!()

      course_teacher = Enum.random(teachers)

      teacher_attrs = %{
        course_id: course.id,
        user_id: course_teacher.user_id,
        role: :teacher,
        approved?: true,
        approved_at: DateTime.utc_now(),
        approved_by_id: Enum.at(managers, 0).user_id
      }

      %CourseUser{} |> CourseUser.changeset(teacher_attrs) |> Repo.insert!()

      Enum.each(students, fn student ->
        create_student(%{student: student, course: course, manager: Enum.at(managers, 0)})
      end)

      Enum.each(@lessons, fn lesson_attrs -> create_lessons(lesson_attrs, course) end)
    end
  end

  defp create_student(%{student: student, course: course, manager: manager}) do
    %CourseUser{}
    |> CourseUser.changeset(%{
      course_id: course.id,
      user_id: student.user_id,
      role: :student,
      approved?: true,
      approved_at: DateTime.utc_now(),
      approved_by_id: manager.user_id
    })
    |> Repo.insert!()
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
