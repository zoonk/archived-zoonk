defmodule UneebeeWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use UneebeeWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Content
  import Uneebee.Fixtures.Organizations

  alias Plug.Conn
  alias Uneebee.Accounts.User
  alias Uneebee.Content.Course
  alias Uneebee.Organizations.School

  using do
    quote do
      use UneebeeWeb, :verified_routes

      import Phoenix.ConnTest

      # Import conveniences for testing with connections
      import Plug.Conn
      import UneebeeWeb.ConnCase

      # The default endpoint for testing
      @endpoint UneebeeWeb.Endpoint
    end
  end

  setup tags do
    Uneebee.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  @spec register_and_log_in_user(%{conn: Conn.t()}) :: %{conn: Conn.t(), user: User.t(), password: String.t()}
  def register_and_log_in_user(%{conn: conn}) do
    attrs = valid_user_attributes()
    user = user_fixture(attrs)
    %{conn: log_in_user(conn, user), user: user, password: attrs.password}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  @spec log_in_user(Conn.t(), User.t()) :: Conn.t()
  def log_in_user(conn, user) do
    token = Uneebee.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Conn.put_session(:user_token, token)
  end

  @doc """
  Setup helper that creates a school and sets its `custom_domain` as the `conn.host` value.

      setup :set_school
  """
  @spec set_school(%{conn: Conn.t()}, map()) :: %{conn: Conn.t(), school: School.t()}
  def set_school(%{conn: conn}, attrs \\ %{}) do
    school = school_fixture(attrs)
    conn = conn |> Map.put(:host, school.custom_domain) |> Conn.assign(:school, school)
    %{conn: conn, school: school}
  end

  @doc """
  Setup helper that registers a user, logs them in, and add them to the app school.

      setup :app_setup
  """
  @spec app_setup(%{conn: Conn.t()}, Keyword.t()) :: %{
          conn: Conn.t(),
          user: User.t(),
          school: School.t(),
          password: String.t()
        }
  def app_setup(%{conn: conn}, opts \\ []) do
    public_school? = Keyword.get(opts, :public_school?, true)
    school_id = Keyword.get(opts, :school_id, nil)

    school_attrs = %{public?: public_school?, school_id: school_id}
    school_user_attrs = opts |> Keyword.get(:school_user, :student) |> get_user_attrs()

    %{conn: register_conn, user: user, password: password} = register_and_log_in_user(%{conn: conn})
    %{conn: school_conn, school: school} = set_school(%{conn: register_conn}, school_attrs)

    if school_user_attrs do
      school_user_fixture(Map.merge(%{school: school, user: user}, school_user_attrs))
    end

    %{conn: school_conn, user: user, school: school, password: password}
  end

  @doc """
  Setup helper for course pages.

  Here's what it does:

  - Registers a user and logs them in.
  - Creates a school and sets its `custom_domain` as the `conn.host` value.
  - Creates a course and sets it as the `conn.assigns.course` value.
  - Handles `school_user` and `course_user` permissions.
  """
  @spec course_setup(%{conn: Conn.t()}, Keyword.t()) :: %{
          conn: Conn.t(),
          user: User.t(),
          school: School.t(),
          course: Course.t()
        }
  def course_setup(%{conn: conn}, opts \\ []) do
    %{conn: app_conn, school: school, user: user} = app_setup(%{conn: conn}, opts)

    public_course? = Keyword.get(opts, :public_course?, true)
    published_course? = Keyword.get(opts, :published_course?, true)
    course_user_attrs = opts |> Keyword.get(:course_user, :student) |> get_user_attrs()

    course = course_fixture(%{school_id: school.id, public?: public_course?, published?: published_course?})

    if course_user_attrs do
      %{course: course, user: user} |> Map.merge(course_user_attrs) |> course_user_fixture()
    end

    %{conn: app_conn, user: user, school: school, course: course}
  end

  defp get_user_attrs(user_kind) do
    case user_kind do
      :manager -> %{role: :manager, approved?: true}
      :teacher -> %{role: :teacher, approved?: true}
      :student -> %{role: :student, approved?: true}
      :pending -> %{role: :student, approved?: false}
      nil -> nil
    end
  end
end
