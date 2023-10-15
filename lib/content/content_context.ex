defmodule Uneebee.Content do
  @moduledoc """
  Content context.
  """
  import Ecto.Query, warn: false

  alias Uneebee.Accounts
  alias Uneebee.Accounts.User
  alias Uneebee.Content.Course
  alias Uneebee.Content.CourseData
  alias Uneebee.Content.CourseUser
  alias Uneebee.Content.CourseUtils
  alias Uneebee.Content.Lesson
  alias Uneebee.Content.LessonStep
  alias Uneebee.Content.StepOption
  alias Uneebee.Content.UserLesson
  alias Uneebee.Content.UserSelection
  alias Uneebee.Gamification
  alias Uneebee.Organizations
  alias Uneebee.Organizations.School
  alias Uneebee.Organizations.SchoolUser
  alias Uneebee.Repo

  @type course_changeset :: {:ok, Course.t()} | {:error, Ecto.Changeset.t()}
  @type course_user_changeset :: {:ok, CourseUser.t()} | {:error, Ecto.Changeset.t()}
  @type lesson_changeset :: {:ok, Lesson.t()} | {:error, Ecto.Changeset.t()}
  @type lesson_step_changeset :: {:ok, LessonStep.t()} | {:error, Ecto.Changeset.t()}
  @type step_option_changeset :: {:ok, StepOption.t()} | {:error, Ecto.Changeset.t()}
  @type user_lesson_changeset :: {:ok, UserLesson.t()} | {:error, Ecto.Changeset.t()}
  @type user_selection_changeset :: {:ok, UserSelection.t()} | {:error, Ecto.Changeset.t()}

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

      iex> list_courses_by_school(%School{})
      [%Course{}, ...]
  """
  @spec list_courses_by_school(School.t()) :: [Course.t()]
  def list_courses_by_school(%School{} = school) do
    Course |> where([c], c.school_id == ^school.id) |> order_by(desc: :inserted_at) |> preload(:school) |> Repo.all()
  end

  @doc """
  Returns all public courses for a given school.

  This is intended to be used for the public API. It's ideal for students and parents.
  If you want all courses, use `list_courses_by_school/1` instead.

  ## Examples

      iex> list_public_courses_by_school(%School{})
      [%CourseData{}, ...]
  """
  @spec list_public_courses_by_school(School.t(), list()) :: [CourseData.t()]
  def list_public_courses_by_school(%School{} = school, opts \\ []) do
    limit = Keyword.get(opts, :limit, nil)

    courses =
      Course
      |> join(:left, [c], u in assoc(c, :users), on: u.role == ^:student)
      |> where([c], c.school_id == ^school.id)
      |> where([c], c.published? and c.public?)
      |> group_by([c], c.id)
      |> order_by([c, u], desc: count(u.id))
      |> limit(^limit)
      |> preload(:school)
      |> select([c, u], {c, count(u.id)})
      |> Repo.all()

    Enum.map(courses, fn {course, student_count} -> %CourseData{id: course.id, data: course, student_count: student_count} end)
  end

  @doc """
  List all courses given a user and a role.

  ## Examples

      iex> list_courses_by_user(%User{}, :teacher)
      [%Course{}, ...]

      iex> list_courses_by_user(%User{}, :student, limit: 5)
      [%Course{}, ...]
  """
  @spec list_courses_by_user(User.t(), atom(), keyword()) :: [Course.t()]
  def list_courses_by_user(%User{} = user, role, opts \\ []) do
    limit = Keyword.get(opts, :limit, nil)

    Course
    |> join(:inner, [c], cu in CourseUser, on: c.id == cu.course_id and cu.user_id == ^user.id and cu.role == ^role)
    |> preload(:school)
    |> order_by(desc: :inserted_at)
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
    Organizations.update_school_user(school_user, course_attrs)
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
  List all users for a course according to their role.

  ## Examples

      iex> list_course_users_by_role(%Course{}, :teacher)
      [%CourseUser{}, ...]

      iex> list_course_users_by_role(%Course{}, :student)
      [%CourseUser{}, ...]
  """
  @spec list_course_users_by_role(Course.t(), atom()) :: [CourseUser.t()]
  def list_course_users_by_role(course, role) do
    CourseUser
    |> where([cu], cu.course_id == ^course.id and cu.role == ^role)
    |> order_by(asc: :approved?)
    |> order_by(desc: :inserted_at)
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
  Gets the number of students from a course.

  ## Examples

      iex> get_course_students_count(%Course{})
      1
  """
  @spec get_course_students_count(Course.t()) :: non_neg_integer()
  def get_course_students_count(course) do
    CourseUser
    |> where([cu], cu.course_id == ^course.id and cu.role == :student)
    |> Repo.aggregate(:count)
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
    %Lesson{} |> change_lesson(attrs) |> Repo.insert()
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
    Repo.delete(lesson)
  end

  @doc """
  List course lessons.

  ## Examples

      iex> list_lessons(%Course{})
      [%Lesson{}, ...]
  """
  @spec list_lessons(Course.t()) :: [Lesson.t()]
  def list_lessons(%Course{} = course) do
    Lesson |> where([l], l.course_id == ^course.id) |> order_by(asc: :order) |> Repo.all()
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
    user_lessons_query = where(UserLesson, [ul], ul.user_id == ^user.id)

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
      |> join(:inner, [us], o in assoc(us, :option))
      |> where([us, o], us.user_id == ^user_id and not o.correct?)
      |> preload(option: [:lesson_step])

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
  Update lessons order.

  Reposition all lessons between an interval when a lesson is moved.

  ## Examples

      iex> update_lesson_order(%Course{}, 1, 3)
      {:ok, [%Lesson{}, ...]}
  """
  @spec update_lesson_order(Course.t(), non_neg_integer(), non_neg_integer()) ::
          {:ok, [Lesson.t()]} | {:error, [Ecto.Changeset.t()]}
  def update_lesson_order(%Course{} = course, from_index, to_index) do
    lessons = list_lessons(course)

    case reorder_items(lessons, from_index, to_index, &change_lesson/2) do
      {:ok, _} -> {:ok, list_lessons(course)}
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
  Deletes a lesson step.

  ## Examples

      iex> delete_lesson_step(123)
      {:ok, %LessonStep{}}

      iex> delete_lesson_step(123)
      {:error, %Ecto.Changeset{}}
  """
  @spec delete_lesson_step(non_neg_integer()) :: lesson_step_changeset()
  def delete_lesson_step(lesson_step_id) do
    LessonStep |> Repo.get!(lesson_step_id) |> Repo.delete()
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
    LessonStep |> where([ls], ls.lesson_id == ^lesson.id and ls.order == ^order + 1) |> preload(:options) |> Repo.one()
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
    |> join(:inner, [us], so in assoc(us, :option))
    |> join(:inner, [us, so], ls in assoc(so, :lesson_step))
    |> where([us, so, ls], ls.lesson_id == ^lesson_id)
    |> order_by([us], desc: us.inserted_at)
    |> limit(^steps)
    |> preload([:option])
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
    case Repo.transaction(fn -> save_lesson(attrs) end) do
      {:ok, user_lesson} -> add_awards_after_lesson(user_lesson)
      {:error, error} -> error
    end
  end

  defp add_user_lesson(attrs, nil) do
    %UserLesson{} |> change_user_lesson(attrs) |> Repo.insert()
  end

  defp add_user_lesson(attrs, %UserLesson{} = user_lesson) do
    attrs = Map.merge(attrs, %{attempts: user_lesson.attempts + 1})
    update_user_lesson(user_lesson, attrs)
  end

  defp save_lesson(attrs) do
    user_id = Map.get(attrs, :user_id)
    lesson_id = Map.get(attrs, :lesson_id)
    user_lesson = get_user_lesson(user_id, lesson_id)

    correct = Map.get(attrs, :correct)
    total = Map.get(attrs, :total)
    perfect? = correct == total
    first_try? = is_nil(user_lesson)

    Gamification.award_medal_for_lesson(%{user_id: user_id, lesson_id: lesson_id, perfect?: perfect?, first_try?: first_try?})

    add_user_lesson(attrs, user_lesson)
  end

  defp add_awards_after_lesson({:ok, user_lesson} = attrs) do
    user = Accounts.get_user!(user_lesson.user_id)
    lesson = Lesson |> Repo.get!(user_lesson.lesson_id) |> Repo.preload(:course)
    lesson_count = count_user_lessons(user.id)
    perfect_lesson_count = count_user_perfect_lessons(user.id)

    Repo.transaction(fn ->
      Gamification.maybe_award_trophy(%{user: user, course: lesson.course})
      Gamification.complete_lesson_mission(user, lesson_count)
      Gamification.complete_perfect_lesson_mission(user, perfect_lesson_count)
    end)

    attrs
  end

  @doc """
  Update a user lesson.

  ## Examples

      iex> update_user_lesson(%UserLesson{}, %{attempts: 1})
      {:ok, %UserLesson{}}

      iex> update_user_lesson(%UserLesson{}, %{attempts: 1})
      {:error, %Ecto.Changeset{}}
  """
  @spec update_user_lesson(UserLesson.t(), map()) :: user_lesson_changeset()
  def update_user_lesson(%UserLesson{} = user_lesson, attrs) do
    user_lesson |> change_user_lesson(attrs) |> Repo.update()
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
    Repo.get_by(UserLesson, user_id: user_id, lesson_id: lesson_id)
  end

  @doc """
  Mark a lesson as completed given a user and a lesson.

  This checks the database for all selections a user made last time they took this lesson.
  Then, it marks this lesson as commpleted and updates the score.

  ## Examples

      iex> mark_lesson_as_completed(user_id, lesson_id)
      {:ok, %UserLesson{}}

      iex> mark_lesson_as_completed(user_id, lesson_id)
      {:error, %Ecto.Changeset{}}
  """
  @spec mark_lesson_as_completed(non_neg_integer(), non_neg_integer()) :: user_lesson_changeset()
  def mark_lesson_as_completed(user_id, lesson_id) do
    steps = count_lesson_steps(lesson_id)
    selections = list_user_selections_by_lesson(user_id, lesson_id, steps)
    correct = get_correct_selections(selections)
    attrs = %{user_id: user_id, lesson_id: lesson_id, attempts: 1, correct: correct, total: steps}
    add_user_lesson(attrs)
  end

  defp get_correct_selections(selections) do
    Enum.count(selections, fn selection -> selection.option.correct? end)
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
  Count how many lessons a user has completed.

  ## Examples

      iex> count_user_lessons(user_id)
      1
  """
  @spec count_user_lessons(non_neg_integer()) :: non_neg_integer()
  def count_user_lessons(user_id) do
    UserLesson |> where([ul], ul.user_id == ^user_id) |> Repo.aggregate(:count)
  end

  @doc """
  Count how many perfect lessons a user has completed.

  ## Examples

      iex> count_user_perfect_lessons(user_id)
      1
  """
  @spec count_user_perfect_lessons(non_neg_integer()) :: non_neg_integer()
  def count_user_perfect_lessons(user_id) do
    UserLesson |> where([ul], ul.user_id == ^user_id and ul.correct == ul.total) |> Repo.aggregate(:count)
  end
end
