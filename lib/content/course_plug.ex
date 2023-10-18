defmodule UneebeeWeb.Plugs.Course do
  @moduledoc """
  Mounts the course data and permissions.
  """
  use UneebeeWeb, :verified_routes

  import Plug.Conn

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
  Requires a school manager or course teacher to access a page.
  """
  @spec require_manager_or_course_teacher(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def require_manager_or_course_teacher(conn, _opts) do
    %{school_user: school_user, course_user: course_user} = conn.assigns
    require_manager_or_course_teacher(conn, school_user, course_user)
  end

  @doc """
  Requires a course user to access a page.
  """
  @spec require_course_user_for_lesson(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def require_course_user_for_lesson(%Plug.Conn{params: %{"lesson_id" => _lesson_id}} = conn, opts), do: require_course_user_for_lesson(conn, opts, conn.assigns.course_user)
  def require_course_user_for_lesson(conn, _opts), do: conn
  defp require_course_user_for_lesson(%Plug.Conn{assigns: %{current_user: nil}} = conn, _opts, nil), do: redirect_to_login(conn)
  defp require_course_user_for_lesson(_conn, _opts, nil), do: raise(UneebeeWeb.PermissionError, code: :not_enrolled)
  defp require_course_user_for_lesson(_conn, _opts, %{approved?: false}), do: raise(UneebeeWeb.PermissionError, code: :pending_approval)
  defp require_course_user_for_lesson(conn, _opts, _cu), do: conn

  @doc """
  Handles mounting the course data to a LiveView.

  ## `on_mount` options

    * `:mount_course` - Mounts the course from the `course_slug` paramater.
    * `:mount_lesson` - Mounts the lesson from the `lesson_id` paramater.
  """
  @spec on_mount(atom(), LiveView.unsigned_params(), map(), Socket.t()) :: {:cont, Socket.t()}
  def on_mount(:mount_course, %{"course_slug" => course_slug}, _session, socket) do
    %{school: school, current_user: user} = socket.assigns
    course = Content.get_course_by_slug!(course_slug, school.id)
    course_user = get_course_user(course, user)
    course_role = get_course_role(course_user)

    socket =
      socket
      |> Phoenix.Component.assign(:course, course)
      |> Phoenix.Component.assign(:course_user, course_user)
      |> Phoenix.Component.assign(:course_role, course_role)

    {:cont, socket}
  end

  def on_mount(:mount_course, _params, _session, socket), do: {:cont, socket}

  def on_mount(:mount_lesson, %{"lesson_id" => lesson_id}, _session, socket) do
    lesson = Content.get_lesson!(lesson_id)
    socket = Phoenix.Component.assign(socket, :lesson, lesson)
    {:cont, socket}
  end

  def on_mount(:mount_lesson, _params, _session, socket), do: {:cont, socket}

  defp require_manager_or_course_teacher(conn, %{role: :manager}, _cu), do: conn
  defp require_manager_or_course_teacher(conn, _su, %{role: :teacher}), do: conn
  defp require_manager_or_course_teacher(_conn, _su, _cu), do: raise(UneebeeWeb.PermissionError, code: :require_manager_or_teacher)

  defp get_course_user(_course, nil), do: nil
  defp get_course_user(course, user), do: Content.get_course_user_by_id(course.id, user.id)

  defp get_course_role(nil), do: nil
  defp get_course_role(%{approved?: false}), do: :pending
  defp get_course_role(%{role: role}), do: role

  defp redirect_to_login(conn), do: conn |> Controller.redirect(to: ~p"/users/login") |> halt()
end
