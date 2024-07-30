defmodule Zoonk.Content do
  @moduledoc """
  Content context.
  """
  import Ecto.Query, warn: false
  import ZoonkWeb.Gettext

  alias Zoonk.Accounts.User
  alias Zoonk.Content.Course
  alias Zoonk.Content.CourseData
  alias Zoonk.Content.CourseUser
  alias Zoonk.Content.CourseUtils
  alias Zoonk.Content.Lesson
  alias Zoonk.Content.LessonStep
  alias Zoonk.Content.StepOption
  alias Zoonk.Content.StepSuggestedCourse
  alias Zoonk.Content.UserLesson
  alias Zoonk.Content.UserSelection
  alias Zoonk.Organizations
  alias Zoonk.Organizations.School
  alias Zoonk.Organizations.SchoolUser
  alias Zoonk.Repo

  @type course_changeset :: {:ok, Course.t()} | {:error, Ecto.Changeset.t()}
  @type course_user_changeset :: {:ok, CourseUser.t()} | {:error, Ecto.Changeset.t()}
  @type lesson_changeset :: {:ok, Lesson.t()} | {:error, Ecto.Changeset.t()}
  @type lesson_step_changeset :: {:ok, LessonStep.t()} | {:error, Ecto.Changeset.t()}
  @type step_option_changeset :: {:ok, StepOption.t()} | {:error, Ecto.Changeset.t()}
  @type step_suggested_course_changeset :: {:ok, StepSuggestedCourse.t()} | {:error, Ecto.Changeset.t()}
  @type user_lesson_changeset :: {:ok, UserLesson.t()} | {:error, Ecto.Changeset.t()}
  @type user_selection_changeset :: {:ok, UserSelection.t()} | {:error, Ecto.Changeset.t()}

  @type lesson_stats :: %{users: non_neg_integer()}

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking course changes.

  ## Examples

      iex> change_course(%Course{})
      %Ecto.Changeset{data: %Course{}}
  """
  @spec change_course(Course.t(), map()) :: Ecto.Changeset.t()
  def change_course(course, attrs \\ %{}) do
    Course.changeset(course, attrs)
  end

  @doc """
  Creates a course.

  ## Examples

      iex> create_course(%{field: value}, %User{})
      {:ok, %Course{}}

      iex> create_course(%{field: bad_value}, %User{})
      {:error, %Ecto.Changeset{}}
  """
  @spec create_course(map(), User.t()) :: course_changeset()
  def create_course(attrs \\ %{}, user) do
    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:course, Course.changeset(%Course{}, attrs))
      |> Ecto.Multi.run(:course_user, fn _repo, %{course: course} ->
        create_course_user(course, user, %{role: :teacher, approved?: true, approved_at: DateTime.utc_now(), approved_by_id: user.id})
      end)
      |> Ecto.Multi.run(:lesson, fn _repo, %{course: course} ->
        create_lesson(%{
          course_id: course.id,
          order: 1,
          name: dgettext("orgs", "Lesson %{order}", order: 1),
          description: dgettext("orgs", "Description for lesson %{order}. You should update this.", order: 1)
        })
      end)

    case Repo.transaction(multi) do
      {:ok, %{course: course}} -> {:ok, get_course!(course.id)}
      {:error, _failed_operation, changeset, _changes_so_far} -> {:error, changeset}
    end
  end

  @doc """
  Updates a course.

  ## Examples

      iex> update_course(%Course{}, %{field: value})
      {:ok, %Course{}}

      iex> update_course(%Course{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  @spec update_course(Course.t(), map()) :: course_changeset()
  def update_course(%Course{} = course, attrs \\ %{}) do
    course |> change_course(attrs) |> Repo.update()
  end

  @doc """
  Get a course by ID.

  ## Examples

      iex> get_course!(123)
      %Course{}

      iex> get_course!(456)
      ** (Ecto.NoResultsError)
  """
  @spec get_course!(non_neg_integer()) :: Course.t()
  def get_course!(id) do
    Repo.get!(Course, id)
  end

  @doc """
  Gets a single course based on the given slug and school ID.

  ## Examples

      iex> get_course_by_slug!("slug", 123)
      %Course{}

      iex> get_course_by_slug!("bad-slug", 123)
      ** (Ecto.NoResultsError)
  """
  @spec get_course_by_slug!(String.t(), non_neg_integer()) :: Course.t()
  def get_course_by_slug!(slug, school_id) do
    Repo.get_by!(Course, slug: slug, school_id: school_id)
  end

  @doc """
  Returns all courses for a given school.

  This is intended to be used for the management panel. It's ideal for managers and teachers.
  If you want only published courses, use `list_public_courses_by_school/2` instead.

  ## Examples

      iex> list_courses_by_school(school_id)
      [%Course{}, ...]
  """
  @spec list_courses_by_school(non_neg_integer()) :: [Course.t()]
  def list_courses_by_school(school_id) do
    Course |> where([c], c.school_id == ^school_id) |> order_by(desc: :inserted_at) |> preload(:school) |> Repo.all()
  end

  @doc """
  Returns all public courses for a given school.

  This is intended to be used for the public API. It's ideal for students and parents.
  If you want all courses, use `list_courses_by_school/1` instead.

  ## Examples

      iex> list_public_courses_by_school(%School{})
      [%CourseData{}, ...]
  """
  @spec list_public_courses_by_school(School.t(), atom(), list()) :: [CourseData.t()]
  def list_public_courses_by_school(%School{} = school, language, opts \\ []) do
    limit = Keyword.get(opts, :limit, nil)

    courses =
      Course
      |> join(:left, [c], u in assoc(c, :users), on: u.role == ^:student)
      |> where([c], c.school_id == ^school.id)
      |> where([c], c.published? and c.public? and c.language == ^language)
      |> group_by([c], c.id)
      |> order_by([c, u], desc: count(u.id))
      |> limit(^limit)
      |> preload(:school)
      |> select([c, u], {c, count(u.id)})
      |> Repo.all()

    Enum.map(courses, fn {course, student_count} -> %CourseData{id: course.id, data: course, student_count: student_count} end)
  end

  @doc """
  Search courses by name and slug.

  It displays only courses from the specified school.

  ## Examples

      iex> search_courses_by_school(school_id, "course")
      [%Course{}, ...]

      iex> search_courses_by_school(school_id, "invalid")
      []
  """
  @spec search_courses_by_school(non_neg_integer(), String.t()) :: [Course.t()]
  def search_courses_by_school(school_id, term) do
    search_term = "%#{term}%"
    combined_name_search_term = search_term |> String.split(" ") |> Enum.join(" ")

    Course
    |> where([c], c.school_id == ^school_id and c.published?)
    |> where(
      [c],
      ilike(c.name, ^search_term) or
        ilike(c.slug, ^search_term) or
        ilike(fragment("? || ' ' || ?", c.name, c.slug), ^combined_name_search_term)
    )
    |> order_by(desc: :updated_at)
    |> Repo.all()
  end

  @doc """
  List all courses given a user and a role.

  ## Examples

      iex> list_courses_by_user(school_id, user_id, :teacher)
      [%Course{}, ...]

      iex> list_courses_by_user(school_id, user_id, :student, limit: 5)
      [%Course{}, ...]
  """
  @spec list_courses_by_user(non_neg_integer(), non_neg_integer(), atom(), keyword()) :: [Course.t()]
  def list_courses_by_user(school_id, user_id, role, opts \\ []) do
    limit = Keyword.get(opts, :limit, nil)

    Course
    |> join(:inner, [c], s in assoc(c, :school), on: s.id == ^school_id)
    |> join(:inner, [c, _s], cu in CourseUser, on: c.id == cu.course_id and cu.user_id == ^user_id and cu.role == ^role)
    |> preload(:school)
    |> order_by(desc: :updated_at)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Deletes a course.

  ## Examples

      iex> delete_course(%Course{})
      {:ok, %Course{}}

      iex> delete_course(%Course{})
      {:error, %Ecto.Changeset{}}
  """
  @spec delete_course(Course.t()) :: course_changeset()
  def delete_course(course) do
    Repo.delete(course)
  end

  @doc """
  Adds a user to a course.

  ## Examples

      iex> create_course_user(%Course{}, %User{}, %{role: :student})
      {:ok, %CourseUser{}}

      iex> create_course_user(%Course{}, %User{}, %{role: :invalid})
      {:error, %Ecto.Changeset{}}
  """
  @spec create_course_user(Course.t(), User.t(), map()) :: course_user_changeset()
  def create_course_user(course, user, attrs \\ %{}) do
    course_user_attrs = Enum.into(attrs, %{course_id: course.id, user_id: user.id})
    school = Organizations.get_school!(course.school_id)
    school_user = Organizations.get_school_user(school.slug, user.username)

    case Repo.transaction(fn ->
           handle_school_user(school, user, school_user, course_user_attrs)

           %CourseUser{}
           |> CourseUser.changeset(course_user_attrs)
           |> Repo.insert()
         end) do
      {:ok, course_user} -> course_user
      {:error, changeset} -> changeset
    end
  end

  defp handle_school_user(school, user, nil, course_attrs) do
    school_user_attrs = Enum.into(course_attrs, %{school_id: school.id, user_id: user.id})
    Organizations.create_school_user(school, user, school_user_attrs)
  end

  defp handle_school_user(_school, _user, %SchoolUser{role: :student} = school_user, %{role: :teacher} = course_attrs) do
    Organizations.update_school_user(school_user.id, course_attrs)
  end

  defp handle_school_user(_school, _user, _su, _course_attrs), do: nil

  @doc """
  Get a user from a course given their ID.

  ## Examples

      iex> get_course_user_by_id(1, 1)
      %CourseUser{}

      iex> get_course_user_by_id(0, 0)
      ** nil
  """
  @spec get_course_user_by_id(non_neg_integer(), non_neg_integer(), list()) :: CourseUser.t() | nil
  def get_course_user_by_id(course_id, user_id, opts \\ []) do
    preload = Keyword.get(opts, :preload, [])
    CourseUser |> Repo.get_by(course_id: course_id, user_id: user_id) |> Repo.preload(preload)
  end

  @doc """
  Search course users.

  Search a course user by `first_name`, `last_name`, `username` or `email`.

  ## Examples

      iex> search_course_users(course_id, "will")
      [%CourseUser{}, ...]

      iex> search_course_users(course_id, "will ceolin")
      [%CourseUser{}, ...]

      iex> search_course_users(course_id, "will@zoonk.org")
      [%CourseUser{}, ...]

      iex> search_course_users(course_id, "invalid)
      []
  """
  @spec search_course_users(non_neg_integer(), String.t()) :: [CourseUser.t()]
  def search_course_users(course_id, term) do
    search_term = "%#{term}%"
    combined_name_search_term = search_term |> String.split(" ") |> Enum.join(" ")

    CourseUser
    |> join(:inner, [cu], u in User, on: cu.user_id == u.id)
    |> where([cu, u], cu.course_id == ^course_id)
    |> where(
      [cu, u],
      ilike(u.username, ^search_term) or
        ilike(u.email, ^search_term) or
        ilike(u.first_name, ^search_term) or
        ilike(u.last_name, ^search_term) or
        ilike(fragment("? || ' ' || ?", u.first_name, u.last_name), ^combined_name_search_term)
    )
    |> preload([cu, u], user: u)
    |> Repo.all()
  end

  @doc """
  List all users for a course.

  ## Examples

      iex> list_course_users(course_id)
      [%CourseUser{}, ...]

      iex> list_course_users(course_id)
      [%CourseUser{}, ...]
  """
  @spec list_course_users(non_neg_integer(), list()) :: [CourseUser.t()]
  def list_course_users(course_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, nil)
    offset = Keyword.get(opts, :offset, nil)

    CourseUser
    |> where([cu], cu.course_id == ^course_id)
    |> order_by(asc: :approved?)
    |> order_by(desc: :inserted_at)
    |> limit(^limit)
    |> offset(^offset)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Updates a course user.

  ## Examples

      iex> update_course_user(%CourseUser{}, %{role: :student})
      {:ok, %CourseUser{}}

      iex> update_course_user(%CourseUser{}, %{role: :invalid})
      {:error, %Ecto.Changeset{}}
  """
  @spec update_course_user(CourseUser.t(), map()) :: course_user_changeset()
  def update_course_user(course_user, attrs) do
    course_user |> CourseUser.changeset(attrs) |> Repo.update()
  end

  @doc """
  Approves a course user.

  ## Examples

      iex> approve_course_user(school_user_id, approved_by_id)
      {:ok, %CourseUser{}}

      iex> approve_course_user(school_user_id, approved_by_id)
      {:error, %Ecto.Changeset{}}
  """
  @spec approve_course_user(non_neg_integer(), non_neg_integer()) :: course_user_changeset()
  def approve_course_user(course_user_id, approved_by_id) do
    CourseUser
    |> Repo.get!(course_user_id)
    |> update_course_user(%{approved?: true, approved_by_id: approved_by_id, approved_at: DateTime.utc_now()})
  end

  @doc """
  Deletes a course user.

  ## Examples

      iex> delete_course_user(course_user_id)
      {:ok, %CourseUser{}}

      iex> delete_course_user(course_user_id)
      {:error, %Ecto.Changeset{}}
  """
  @spec delete_course_user(non_neg_integer()) :: course_user_changeset()
  def delete_course_user(course_user_id) do
    CourseUser |> Repo.get!(course_user_id) |> Repo.delete()
  end

  @doc """
  Get the number of users in a course.

  ## Examples

      iex> get_course_users_count(course_id)
      10
  """
  @spec get_course_users_count(non_neg_integer()) :: non_neg_integer()
  def get_course_users_count(course_id) do
    CourseUser |> where([cu], cu.course_id == ^course_id) |> Repo.aggregate(:count)
  end

  @doc """
  Gets the number of users in a course based on their role.

  ## Examples

      iex> get_course_users_count(%Course{}, :student)
      10
  """
  @spec get_course_users_count(Course.t(), atom()) :: non_neg_integer()
  def get_course_users_count(course, role) do
    CourseUser |> where([cu], cu.course_id == ^course.id and cu.role == ^role) |> Repo.aggregate(:count)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking lesson changes.

  ## Examples

      iex> change_lesson(%Lesson{})
      %Ecto.Changeset{data: %Lesson{}}
  """
  @spec change_lesson(Lesson.t(), map()) :: Ecto.Changeset.t()
  def change_lesson(lesson, attrs \\ %{}) do
    Lesson.changeset(lesson, attrs)
  end

  @doc """
  Creates a new lesson.

  ## Examples

      iex> create_lesson(%{title: "Lesson 1"})
      {:ok, %Lesson{}}

      iex> create_lesson(%{title: "Lesson 1"})
      {:error, %Ecto.Changeset{}}
  """
  @spec create_lesson(map()) :: lesson_changeset()
  def create_lesson(attrs) do
    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:lesson, change_lesson(%Lesson{}, attrs))
      |> Ecto.Multi.run(:lesson_step, fn _repo, %{lesson: lesson} ->
        create_lesson_step(%{lesson_id: lesson.id, order: 1, content: dgettext("orgs", "Untitled step")})
      end)

    case Repo.transaction(multi) do
      {:ok, %{lesson: lesson}} -> {:ok, get_lesson!(lesson.id)}
      {:error, _failed_operation, changeset, _changes_so_far} -> {:error, changeset}
    end
  end

  @doc """
  Updates a lesson.

  ## Examples

      iex> update_lesson(%Lesson{}, %{name: "Lesson 1"})
      {:ok, %Lesson{}}

      iex> update_lesson(%Lesson{}, %{name: "Lesson 1"})
      {:error, %Ecto.Changeset{}}
  """
  @spec update_lesson(Lesson.t(), map()) :: lesson_changeset()
  def update_lesson(%Lesson{} = lesson, attrs) do
    lesson |> change_lesson(attrs) |> Repo.update()
  end

  @doc """
  Deletes a lesson.

  ## Examples

      iex> delete_lesson(%Lesson{})
      {:ok, %Lesson{}}

      iex> delete_lesson(%Lesson{})
      {:error, %Ecto.Changeset{}}
  """
  @spec delete_lesson(Lesson.t()) :: lesson_changeset()
  def delete_lesson(%Lesson{} = lesson) do
    delete_lesson(lesson, count_lessons(lesson.course_id))
  end

  defp delete_lesson(lesson, 1) do
    changeset = lesson |> change_lesson() |> Ecto.Changeset.add_error(:base, dgettext("errors", "cannot delete the only lesson"))
    {:error, changeset}
  end

  defp delete_lesson(lesson, count) do
    update_lesson_order(lesson.course_id, lesson.order - 1, count - 1)
    Repo.delete(lesson)
  end

  @doc """
  List course lessons.

  ## Examples

      iex> list_lessons(course_id)
      [%Lesson{}, ...]
  """
  @spec list_lessons(non_neg_integer()) :: [Lesson.t()]
  def list_lessons(course_id) do
    Lesson |> where([l], l.course_id == ^course_id) |> order_by(asc: :order) |> Repo.all()
  end

  @doc """
  List course lessons with stats.

  ## Examples

      iex> list_lessons_with_stats(course_id)
      [%Lesson{}, ...]
  """
  @spec list_lessons_with_stats(non_neg_integer()) :: [{Lesson.t(), lesson_stats()}]
  def list_lessons_with_stats(course_id) do
    lessons =
      Lesson
      |> where([l], l.course_id == ^course_id)
      |> order_by(asc: :order)
      |> preload(:user_lessons)
      |> Repo.all()

    Enum.map(lessons, fn lesson ->
      stats = %{users: length(lesson.user_lessons)}
      lesson = Map.replace(lesson, :user_lessons, [])
      {lesson, stats}
    end)
  end

  @doc """
  Count how many lessons a course has.

  ## Examples

      iex> count_lessons(course_id)
      1
  """
  @spec count_lessons(non_neg_integer()) :: non_neg_integer()
  def count_lessons(course_id) do
    Lesson |> where([l], l.course_id == ^course_id) |> Repo.aggregate(:count)
  end

  @doc """
  Get the first lesson of a course.

  ## Examples

      iex> get_first_lesson(%Course{})
      %Lesson{}

      iex> get_first_lesson(%Course{})
      nil
  """
  @spec get_first_lesson(Course.t()) :: Lesson.t() | nil
  def get_first_lesson(nil), do: nil

  def get_first_lesson(%Course{} = course) do
    Lesson |> where([l], l.course_id == ^course.id) |> order_by(asc: :order) |> limit(1) |> Repo.one()
  end

  @doc """
  List published lessons.

  ## Examples

      iex> list_published_lessons(%Course{}, %User{})
      [%Lesson{}, ...]
  """
  @spec list_published_lessons(Course.t(), User.t() | nil) :: [Lesson.t()]
  @spec list_published_lessons(Course.t(), User.t(), list()) :: [Lesson.t()]
  def list_published_lessons(%Course{} = course, nil) do
    Lesson |> where([l], l.course_id == ^course.id and l.published?) |> order_by(asc: :order) |> Repo.all()
  end

  def list_published_lessons(%Course{} = course, %User{} = user, opts \\ []) do
    preload_selections? = Keyword.get(opts, :selections?, false)
    user_lessons_query = UserLesson |> where([ul], ul.user_id == ^user.id) |> order_by(desc: :inserted_at)

    Lesson
    |> where([l], l.course_id == ^course.id and l.published?)
    |> order_by(asc: :order)
    |> maybe_preload_user_selections(user.id, preload_selections?)
    |> preload([l], user_lessons: ^user_lessons_query)
    |> Repo.all()
  end

  defp maybe_preload_user_selections(query, _user_id, false), do: query

  defp maybe_preload_user_selections(query, user_id, true) do
    user_selections_query =
      UserSelection
      |> where([us], us.user_id == ^user_id)
      |> where([us], not is_nil(us.answer) or us.total > us.correct)
      |> preload([:step, :option])

    preload(query, [l], user_selections: ^user_selections_query)
  end

  @doc """
  Get a lesson.

  ## Examples

      iex> get_lesson!(1)
      %Lesson{}
  """
  @spec get_lesson!(non_neg_integer()) :: Lesson.t()
  def get_lesson!(id) do
    Repo.get!(Lesson, id)
  end

  @doc """
  Get a lesson from a course.

  If the `public?` option is passed, then it will return the lesson only if it's published.

  ## Examples

      iex> get_lesson!(course_slug, 1)
      %Lesson{}

      iex> get_lesson!(course_slug, 1, public?: true)
      %Lesson{}

      iex> get_lesson!(course_slug, 1, public?: true)
      ** (Ecto.NoResultsError)
  """
  @spec get_lesson!(String.t(), non_neg_integer(), list()) :: Lesson.t()
  def get_lesson!(course_slug, lesson_id, opts \\ []) do
    public? = Keyword.get(opts, :public?, false)

    Lesson
    |> join(:inner, [l], c in assoc(l, :course))
    |> where([l, c], l.id == ^lesson_id and c.slug == ^course_slug)
    |> maybe_query_published(public?)
    |> Repo.one!()
  end

  defp maybe_query_published(query, true), do: where(query, [l, c], l.published?)
  defp maybe_query_published(query, false), do: query

  @doc """
  Update lessons order.

  Reposition all lessons between an interval when a lesson is moved.

  ## Examples

      iex> update_lesson_order(course_id, 1, 3)
      {:ok, [%Lesson{}, ...]}
  """
  @spec update_lesson_order(non_neg_integer(), non_neg_integer(), non_neg_integer()) ::
          {:ok, [Lesson.t()]} | {:error, [Ecto.Changeset.t()]}
  def update_lesson_order(course_id, from_index, to_index) do
    lessons = list_lessons(course_id)

    case reorder_items(lessons, from_index, to_index, &change_lesson/2) do
      {:ok, _} -> {:ok, list_lessons(course_id)}
      {:error, changesets} -> {:error, changesets}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking lesson step changes.

  ## Examples

      iex> change_lesson_step(%LessonStep{})
      %Ecto.Changeset{data: %LessonStep{}}
  """
  @spec change_lesson_step(LessonStep.t(), map()) :: Ecto.Changeset.t()
  def change_lesson_step(lesson_step, attrs \\ %{}) do
    LessonStep.changeset(lesson_step, attrs)
  end

  @doc """
  Creates a new lesson step.

  ## Examples

      iex> create_lesson_step(%{content: "Lesson Step 1"})
      {:ok, %LessonStep{}}

      iex> create_lesson_step(%{content: "Lesson Step 1"})
      {:error, %Ecto.Changeset{}}
  """
  @spec create_lesson_step(map()) :: lesson_step_changeset()
  def create_lesson_step(attrs) do
    %LessonStep{} |> change_lesson_step(attrs) |> Repo.insert()
  end

  @doc """
  Updates a lesson step.
  ## Examples
      iex> update_lesson_step(%LessonStep{}, %{content: "Lesson Step 1"})
      {:ok, %LessonStep{}}
      iex> update_lesson_step(%LessonStep{}, %{content: "Lesson Step 1"})
      {:error, %Ecto.Changeset{}}
  """
  @spec update_lesson_step(LessonStep.t(), map()) :: lesson_step_changeset()
  def update_lesson_step(%LessonStep{} = lesson_step, attrs) do
    lesson_step |> change_lesson_step(attrs) |> Repo.update()
  end

  @doc """
  Deletes a lesson step.

  ## Examples

      iex> delete_lesson_step(123)
      {:ok, %LessonStep{}}

      iex> delete_lesson_step(123)
      {:error, %Ecto.Changeset{}}
  """
  @spec delete_lesson_step(non_neg_integer()) :: lesson_step_changeset()
  def delete_lesson_step(lesson_step_id) do
    step = Repo.get!(LessonStep, lesson_step_id)
    count = count_lesson_steps(step.lesson_id)
    delete_lesson_step(step, count)
  end

  defp delete_lesson_step(step, 1) do
    changeset = step |> change_lesson_step() |> Ecto.Changeset.add_error(:base, dgettext("errors", "cannot delete the only step"))
    {:error, changeset}
  end

  defp delete_lesson_step(step, count) do
    lesson = get_lesson!(step.lesson_id)
    update_lesson_step_order(lesson, step.order - 1, count - 1)
    Repo.delete(step)
  end

  @doc """
  List lesson steps.

  ## Examples

      iex> list_lesson_steps(%Lesson{})
      [%LessonStep{}, ...]
  """
  @spec list_lesson_steps(Lesson.t()) :: [LessonStep.t()]
  def list_lesson_steps(%Lesson{} = lesson) do
    LessonStep |> where([ls], ls.lesson_id == ^lesson.id) |> order_by(asc: :order) |> preload(:options) |> Repo.all()
  end

  @doc """
  Get the next step based on the order from the previous one.
  ## Examples
      iex> get_next_step(%Lesson{}, 1)
      %LessonStep{}
  """
  @spec get_next_step(Lesson.t(), non_neg_integer()) :: LessonStep.t() | nil
  def get_next_step(%Lesson{} = lesson, order) do
    LessonStep
    |> where([ls], ls.lesson_id == ^lesson.id and ls.order == ^order + 1)
    |> preload([:options, suggested_courses: :course])
    |> Repo.one()
  end

  @doc """
  Get a lesson step by its order.

  ## Examples

      iex> get_lesson_step_by_order(lesson_id, 1)
      %LessonStep{}
  """
  @spec get_lesson_step_by_order(non_neg_integer(), non_neg_integer()) :: LessonStep.t() | nil
  def get_lesson_step_by_order(lesson_id, order) do
    LessonStep |> Repo.get_by(lesson_id: lesson_id, order: order) |> Repo.preload(:options)
  end

  @doc """
  Get the count of lesson steps.

  ## Examples

      iex> count_lesson_steps(lesson_id)
      1
  """
  @spec count_lesson_steps(non_neg_integer()) :: non_neg_integer()
  def count_lesson_steps(lesson_id) do
    LessonStep |> where([ls], ls.lesson_id == ^lesson_id) |> Repo.aggregate(:count)
  end

  @doc """
  Count how many times each option from a lesson step have been selected.

  ## Examples

      iex> count_selections_by_lesson_step(lesson_step_id)
      [%{option_id: 1, selections: 1}, ...]
  """
  @spec count_selections_by_lesson_step(non_neg_integer()) :: [%{option_id: non_neg_integer(), selections: non_neg_integer()}]
  def count_selections_by_lesson_step(lesson_step_id) do
    StepOption
    |> where(lesson_step_id: ^lesson_step_id)
    |> join(:left, [so], us in UserSelection, on: so.id == us.option_id)
    |> group_by([so, us], so.id)
    |> select([so, us], %{option_id: so.id, selections: count(us.id)})
    |> Repo.all()
  end

  @doc """
  Update lesson steps order.

  Reposition all lesson steps between an interval when a lesson step is moved.

  ## Examples

      iex> update_lesson_step_order(%Lesson{}, 1, 3)
      {:ok, [%LessonStep{}, ...]}
  """
  @spec update_lesson_step_order(Lesson.t(), non_neg_integer(), non_neg_integer()) :: {:ok, [LessonStep.t()]} | {:error, [Ecto.Changeset.t()]}
  def update_lesson_step_order(%Lesson{} = lesson, from_index, to_index) do
    lesson_steps = list_lesson_steps(lesson)

    case reorder_items(lesson_steps, from_index, to_index, &change_lesson_step/2) do
      {:ok, _} -> {:ok, list_lesson_steps(lesson)}
      {:error, changesets} -> {:error, changesets}
    end
  end

  defp reorder_items(items, from_index, to_index, callback) do
    items_to_move = Enum.at(items, from_index)
    {left, right} = items |> List.delete_at(from_index) |> Enum.split(to_index)
    updated_items = left ++ [items_to_move] ++ right

    changesets =
      updated_items
      |> Enum.with_index()
      |> Enum.map(fn {item, index} -> callback.(item, %{order: index + 1}) end)

    Repo.transaction(fn -> Enum.each(changesets, fn changeset -> Repo.update(changeset) end) end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking step option changes.

  ## Examples

      iex> change_step_option(%StepOption{})
      %Ecto.Changeset{data: %StepOption{}}
  """
  @spec change_step_option(StepOption.t(), map()) :: Ecto.Changeset.t()
  def change_step_option(step_option, attrs \\ %{}) do
    StepOption.changeset(step_option, attrs)
  end

  @doc """
  Creates a new step option.

  ## Examples

      iex> create_step_option(%{title: "Step Option 1"})
      {:ok, %StepOption{}}

      iex> create_step_option(%{title: "Step Option 1"})
      {:error, %Ecto.Changeset{}}
  """
  @spec create_step_option(map()) :: step_option_changeset()
  def create_step_option(attrs) do
    %StepOption{} |> change_step_option(attrs) |> Repo.insert()
  end

  @doc """
  Deletes a step option.

  ## Examples

      iex> delete_step_option(123)
      {:ok, %StepOption{}}

      iex> delete_step_option(123)
      {:error, %Ecto.Changeset{}}
  """
  @spec delete_step_option(non_neg_integer()) :: step_option_changeset()
  def delete_step_option(step_option_id) do
    StepOption |> Repo.get!(step_option_id) |> Repo.delete()
  end

  @doc """
  Update a step option.

  ## Examples

      iex> update_step_option(%StepOption{}, %{title: "Step Option 1"})
      {:ok, %StepOption{}}

      iex> update_step_option(%StepOption{}, %{title: "Step Option 1"})
      {:error, %Ecto.Changeset{}}
  """
  @spec update_step_option(StepOption.t(), map()) :: step_option_changeset()
  def update_step_option(%StepOption{} = step_option, attrs) do
    step_option |> change_step_option(attrs) |> Repo.update()
  end

  @doc """
  Get a step option.

  ## Examples

      iex> get_step_option!(123)
      %StepOption{}
  """
  @spec get_step_option!(non_neg_integer()) :: StepOption.t()
  def get_step_option!(step_option_id) do
    Repo.get!(StepOption, step_option_id)
  end

  @doc """
  Adds a user selection.

  ## Examples

      iex> add_user_selection(%{option_id: 123})
      {:ok, %UserSelection{}}

      iex> add_user_selection(%{})
      {:error, %Ecto.Changeset{}}
  """
  @spec add_user_selection(map()) :: user_selection_changeset()
  def add_user_selection(attrs \\ %{}) do
    %UserSelection{} |> UserSelection.changeset(attrs) |> Repo.insert()
  end

  @doc """
  List user selections for a given user and lesson.

  This lists only selections for the last time a user has taken a lesson. Therefore, we limit it to
  the last `n` selections where `n` is the number of steps a lesson has.

  It orders by `inserted_at` because we want to show the last selection first.

  ## Examples

      iex> list_user_selections_by_lesson(user_id, lesson_id, steps)
      [%UserSelection{}, ...]
  """
  @spec list_user_selections_by_lesson(non_neg_integer(), non_neg_integer(), non_neg_integer()) :: [UserSelection.t()]
  def list_user_selections_by_lesson(user_id, lesson_id, steps) do
    UserSelection
    |> where([us], us.user_id == ^user_id)
    |> where([us], us.lesson_id == ^lesson_id)
    |> order_by([us], desc: us.inserted_at)
    |> limit(^steps)
    |> Repo.all()
  end

  @doc """
  Changes a user lesson.

  ## Examples

      iex> change_user_lesson(%UserLesson{}, %{attempts: 1})
      {:ok, %UserLesson{}}

      iex> change_user_lesson(%UserLesson{}, %{attempts: 1})
      {:error, %Ecto.Changeset{}}
  """
  @spec change_user_lesson(UserLesson.t(), map()) :: Ecto.Changeset.t()
  def change_user_lesson(user_lesson, attrs \\ %{}) do
    UserLesson.changeset(user_lesson, attrs)
  end

  @doc """
  Adds a user lesson.

  Marks a lesson as completed when a user finishes it. If the user has completed this lesson before,
  then it updates the score and increases the number of attempts.

  ## Examples

      iex> add_user_lesson(%{user_id: 123})
      {:ok, %UserLesson{}}

      iex> add_user_lesson(%{user_id: 123})
      {:error, %Ecto.Changeset{}}
  """
  @spec add_user_lesson(map()) :: user_lesson_changeset()
  def add_user_lesson(attrs \\ %{}) do
    save_lesson(attrs)
  end

  defp add_user_lesson(attrs, nil) do
    %UserLesson{} |> change_user_lesson(attrs) |> Repo.insert()
  end

  defp add_user_lesson(attrs, %UserLesson{} = user_lesson) do
    attrs = Map.put(attrs, :attempts, user_lesson.attempts + 1)
    add_user_lesson(attrs, nil)
  end

  defp save_lesson(attrs) do
    user_id = Map.get(attrs, :user_id)
    lesson_id = Map.get(attrs, :lesson_id)
    user_lesson = get_user_lesson(user_id, lesson_id)

    add_user_lesson(attrs, user_lesson)
  end

  @doc """
  Get a user lesson.

  ## Examples

      iex> get_user_lesson(user_id, lesson_id)
      %UserLesson{}

      iex> get_user_lesson(user_id, lesson_id)
      ** nil
  """
  @spec get_user_lesson(non_neg_integer(), non_neg_integer()) :: UserLesson.t() | nil
  def get_user_lesson(user_id, lesson_id) do
    UserLesson
    |> where([ul], ul.user_id == ^user_id and ul.lesson_id == ^lesson_id)
    |> order_by(desc: :inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Mark a lesson as completed given a user and a lesson.

  This checks the database for all selections a user made last time they took this lesson.
  Then, it marks this lesson as commpleted and updates the score.

  ## Examples

      iex> mark_lesson_as_completed(user_id, lesson_id, duration)
      {:ok, %UserLesson{}}

      iex> mark_lesson_as_completed(user_id, lesson_id, duration)
      {:error, %Ecto.Changeset{}}
  """
  @spec mark_lesson_as_completed(non_neg_integer(), non_neg_integer(), non_neg_integer()) :: user_lesson_changeset()
  def mark_lesson_as_completed(user_id, lesson_id, duration) do
    steps = count_lesson_steps(lesson_id)
    selections = list_user_selections_by_lesson(user_id, lesson_id, steps)
    correct = sum_correct_selections(selections)
    total = sum_total_selections(selections)
    attrs = %{user_id: user_id, lesson_id: lesson_id, attempts: 1, correct: correct, total: total, duration: duration}
    add_user_lesson(attrs)
  end

  # sum all correct answers a user has given in a lesson
  defp sum_correct_selections(selections) do
    Enum.reduce(selections, 0, fn selection, acc -> acc + selection.correct end)
  end

  # sum all total answers a user has given in a lesson
  defp sum_total_selections(selections) do
    Enum.reduce(selections, 0, fn selection, acc -> acc + selection.total end)
  end

  @doc """
  Returns `true` if a course is completed.

  ## Examples

      iex> course_completed?(user, course)
      true
  """
  @spec course_completed?(User.t(), Course.t()) :: boolean()
  def course_completed?(%User{} = user, %Course{} = course) do
    lessons = list_published_lessons(course, user)
    progress = CourseUtils.course_progress(lessons, user)
    progress == 100
  end

  @doc """
  Get the `slug` of the last course a user has completed a lesson from.

  ## Examples

      iex> get_last_completed_course_slug(user)
      "course-slug"
  """
  @spec get_last_completed_course_slug(School.t(), User.t() | nil) :: String.t() | nil
  def get_last_completed_course_slug(nil, _user), do: nil
  def get_last_completed_course_slug(_school, nil), do: nil

  def get_last_completed_course_slug(%School{id: school_id}, %User{id: user_id}) do
    UserLesson
    |> join(:inner, [ul], l in assoc(ul, :lesson))
    |> join(:inner, [_, l], c in assoc(l, :course))
    |> where([ul, _, c], ul.user_id == ^user_id and c.school_id == ^school_id)
    |> order_by(desc: :updated_at)
    |> limit(1)
    |> preload(lesson: [:course])
    |> Repo.one()
    |> handle_last_completed_course()
  end

  defp handle_last_completed_course(nil), do: nil
  defp handle_last_completed_course(%UserLesson{} = user_lesson), do: user_lesson.lesson.course.slug

  @doc """
  Get the latest course a teacher edit.

  We use as a reference the last lesson a teacher has edited.

  ## Examples

      iex> get_last_edited_course(school, user, role)
      %Course{}

      iex> get_last_edited_course(school, user, role)
      nil
  """
  @spec get_last_edited_course(School.t(), User.t(), atom()) :: Course.t() | nil
  def get_last_edited_course(%School{} = school, _user, :manager) do
    Lesson
    |> join(:inner, [l], c in assoc(l, :course))
    |> where([l, c], c.school_id == ^school.id)
    |> order_by(desc: :updated_at)
    |> limit(1)
    |> preload(:course)
    |> Repo.one()
    |> handle_last_edited_course(school)
  end

  def get_last_edited_course(nil, _user, _role), do: nil

  def get_last_edited_course(school, %User{} = user, role) do
    school.id |> list_courses_by_user(user.id, role, limit: 1) |> Enum.at(0)
  end

  defp handle_last_edited_course(nil, %School{} = school) do
    Course
    |> where([c], c.school_id == ^school.id)
    |> order_by(desc: :updated_at)
    |> limit(1)
    |> Repo.one()
  end

  defp handle_last_edited_course(%Lesson{} = lesson, _school), do: lesson.course

  @doc """
  Add a suggested course to a lesson step.

  ## Examples

      iex> add_step_suggested_course(%{lesson_step_id: 123, course_id: 456})
      {:ok, %StepSuggestedCourse{}}

      iex> add_step_suggested_course(%{})
      {:error, %Ecto.Changeset{}}
  """
  @spec add_step_suggested_course(map()) :: step_suggested_course_changeset()
  def add_step_suggested_course(attrs \\ %{}) do
    %StepSuggestedCourse{} |> StepSuggestedCourse.changeset(attrs) |> Repo.insert()
  end

  @doc """
  Delete a suggested course from a lesson step.

  ## Examples

      iex> delete_step_suggested_course(123)
      {:ok, %StepSuggestedCourse{}}

      iex> delete_step_suggested_course(123)
      {:error, %Ecto.Changeset{}}
  """
  @spec delete_step_suggested_course(non_neg_integer()) :: step_suggested_course_changeset()
  def delete_step_suggested_course(step_suggested_course_id) do
    StepSuggestedCourse |> Repo.get!(step_suggested_course_id) |> Repo.delete()
  end

  @doc """
  List all suggested courses for a lesson step.

  It preloads the course data.

  ## Examples

      iex> list_step_suggested_courses(lesson_step_id)
      [%StepSuggestedCourse{}, ...]
  """
  @spec list_step_suggested_courses(non_neg_integer()) :: [StepSuggestedCourse.t()]
  def list_step_suggested_courses(lesson_step_id) do
    StepSuggestedCourse |> where([ssc], ssc.lesson_step_id == ^lesson_step_id) |> preload(:course) |> Repo.all()
  end
end
