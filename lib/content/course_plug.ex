defmodule UneebeeWeb.Plugs.Course do
  @moduledoc """
  Mounts the course data and permissions.
  """
  use UneebeeWeb, :verified_routes

  import Plug.Conn

  alias Phoenix.Component
  alias Phoenix.Controller
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket
  alias Uneebee.Content

  @doc """
  Fetches the course's data from the database.
  """
  @spec fetch_course(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def fetch_course(%Plug.Conn{params: %{"course_slug" => course_slug}} = conn, _opts) do
    %{school: school, current_user: user} = conn.assigns
    course = Content.get_course_by_slug!(course_slug, school.id)
    course_user = get_course_user(course, user)
    course_role = get_course_role(course_user)

    conn |> assign(:course, course) |> assign(:course_user, course_user) |> assign(:course_role, course_role)
  end

  def fetch_course(conn, _opts), do: conn

  @doc """
  Requires a course user to access a page.
  """
  @spec require_course_user_for_lesson(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def require_course_user_for_lesson(%Plug.Conn{assigns: %{course: %{public?: true}}, params: %{"lesson_id" => _lesson_id}} = conn, _opts), do: maybe_create_course_user(conn)
  def require_course_user_for_lesson(%Plug.Conn{params: %{"lesson_id" => _lesson_id}} = conn, opts), do: require_course_user_for_lesson(conn, opts, conn.assigns.course_user)
  def require_course_user_for_lesson(conn, _opts), do: conn
  defp require_course_user_for_lesson(%Plug.Conn{assigns: %{current_user: nil}} = conn, _opts, nil), do: redirect_to_login(conn)
  defp require_course_user_for_lesson(_conn, _opts, nil), do: raise(UneebeeWeb.PermissionError, code: :not_enrolled)
  defp require_course_user_for_lesson(_conn, _opts, %{approved?: false}), do: raise(UneebeeWeb.PermissionError, code: :pending_approval)
  defp require_course_user_for_lesson(conn, _opts, _cu), do: conn

  defp maybe_create_course_user(%Plug.Conn{assigns: %{course: course, current_user: user, course_user: nil}} = conn) do
    Content.create_course_user(course, user, %{role: :student, approved?: true, approved_by_id: user.id, approved_at: DateTime.utc_now()})
    conn
  end

  defp maybe_create_course_user(conn), do: conn

  @doc """
  Handles mounting the course data to a LiveView.

  ## `on_mount` options

    * `:mount_course` - Mounts the course from the `course_slug` paramater.
    * `:mount_lesson` - Mounts the lesson from the `lesson_id` paramater.
    * `:mount_course_list` - Mounts the list of courses for the school.
  """
  @spec on_mount(atom(), LiveView.unsigned_params(), map(), Socket.t()) :: {:cont, Socket.t()}
  def on_mount(:mount_course, params, _session, socket) do
    %{school: school, current_user: user, user_role: role} = socket.assigns
    course = get_course(params, school, user, role)
    course_user = get_course_user(course, user)
    course_role = get_course_role(course_user)
    first_lesson = Content.get_first_lesson(course)
    first_lesson_id = if is_nil(first_lesson), do: nil, else: first_lesson.id
    last_course_slug = get_last_course_slug(school, user)

    socket =
      socket
      |> Component.assign(:course, course)
      |> Component.assign(:course_user, course_user)
      |> Component.assign(:course_role, course_role)
      |> Component.assign(:first_lesson_id, first_lesson_id)
      |> Component.assign(:last_course_slug, last_course_slug)

    {:cont, socket}
  end

  def on_mount(:mount_lesson, %{"course_slug" => course_slug, "lesson_id" => lesson_id}, _session, socket) do
    dashboard? = socket.view |> Atom.to_string() |> String.contains?("Dashboard")
    lesson = Content.get_lesson!(course_slug, lesson_id, public?: not dashboard?)
    socket = Component.assign(socket, :lesson, lesson)
    {:cont, socket}
  end

  def on_mount(:mount_lesson, _params, _session, socket), do: {:cont, socket}

  defp get_course_user(_course, nil), do: nil
  defp get_course_user(nil, _user), do: nil
  defp get_course_user(course, user), do: Content.get_course_user_by_id(course.id, user.id)

  defp get_last_course_slug(_school, nil), do: nil
  defp get_last_course_slug(school, user), do: Content.get_last_completed_course_slug(school, user)

  defp get_course_role(nil), do: nil
  defp get_course_role(%{approved?: false}), do: :pending
  defp get_course_role(%{role: role}), do: role

  defp get_course(%{"course_slug" => slug}, school, _user, _role), do: Content.get_course_by_slug!(slug, school.id)
  defp get_course(_params, school, user, nil), do: Content.get_last_edited_course(school, user, :student)
  defp get_course(_params, school, user, role), do: Content.get_last_edited_course(school, user, role)

  defp redirect_to_login(conn), do: conn |> Controller.redirect(to: ~p"/users/login") |> halt()
end
