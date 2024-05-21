defmodule ZoonkWeb.Plugs.School do
  @moduledoc """
  This is a multi-tenant app where we assign schools depending on the `host` value.

  ### Examples

  - `zoonk.io` -> `zoonk` school
  - `davinci.zoonk.io` -> `davinci` school using the slug as the subdomain
  - `interactive.harvard.edu` -> `harvard` school using a custom domain

  This means we need to fetch the app school's data when starting this application.
  """
  use ZoonkWeb, :verified_routes

  import Plug.Conn

  alias Phoenix.Controller
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket
  alias Zoonk.Organizations
  alias Zoonk.Organizations.School

  @doc """
  Fetches the school's data from the database.
  """
  @spec fetch_school(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def fetch_school(conn, _opts) do
    school = get_school(conn)
    school_user = get_school_user(school, conn.assigns.current_user)
    user_approved? = if is_map(school_user), do: school_user.approved?, else: false
    user_role = if user_approved?, do: school_user.role

    conn
    |> assign(:school, school)
    |> assign(:school_user, school_user)
    |> assign(:user_role, user_role)
  end

  @doc """
  Checks if the school is already configured.

  If so, then we don't want to show the configuration page.
  """
  @spec check_school_setup(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def check_school_setup(%{request_path: "/schools/new"} = conn, opts), do: check_school_setup(conn, opts, conn.assigns.school)
  def check_school_setup(conn, _opts), do: conn

  # If the school is already configured, we don't want to show the configuration page.
  defp check_school_setup(_conn, _opts, %School{kind: :white_label}), do: raise(ZoonkWeb.PermissionError, code: :school_already_configured)
  defp check_school_setup(conn, _opts, _school), do: conn

  @doc """
  Redirect to the setup page if the school isn't configured.
  """
  @spec setup_school(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def setup_school(%{request_path: "/"} = conn, opts), do: setup_school(conn, opts, is_nil(conn.assigns.school))
  def setup_school(conn, _opts), do: conn

  defp setup_school(conn, _opts, false), do: conn
  defp setup_school(conn, _opts, true), do: conn |> Controller.redirect(to: ~p"/schools/new") |> halt()

  @doc """
  Don't allow a guest user to create a school. Redirect them to the settings page instead.
  """
  @spec prevent_guest_to_create_school(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def prevent_guest_to_create_school(%{request_path: "/schools/new", assigns: %{current_user: %{guest?: true}}} = conn, _opts),
    do: conn |> Controller.redirect(to: ~p"/users/settings") |> halt()

  def prevent_guest_to_create_school(conn, _opts), do: conn

  @doc """
  Requires a subscription for private schools.
  """
  @spec require_subscription_for_private_schools(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  @spec require_subscription_for_private_schools(Plug.Conn.t(), boolean(), map()) :: Plug.Conn.t()
  def require_subscription_for_private_schools(%Plug.Conn{assigns: %{school: nil}} = conn, _opts), do: conn

  def require_subscription_for_private_schools(conn, _opts) do
    %{school: school, school_user: school_user} = conn.assigns
    require_subscription_for_private_schools(conn, school.public?, school_user)
  end

  # If the school is public, then we don't need to check for a subscription.
  defp require_subscription_for_private_schools(conn, true, _school_user), do: conn

  # If the user is approved? (has subscription), then they have access.
  defp require_subscription_for_private_schools(conn, false, school_user) when school_user.approved?, do: conn

  # If the user is not approved? (doesn't have subscription) and school is private, then they don't have access.
  defp require_subscription_for_private_schools(_conn, false, _school_user), do: raise(ZoonkWeb.PermissionError, code: :pending_approval)

  @doc """
  Requires `manager` permissions to access a certain route.
  """
  @spec require_manager(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def require_manager(conn, opts) do
    %{school_user: school_user} = conn.assigns
    approved? = if school_user, do: school_user.approved?, else: false
    role = if school_user, do: school_user.role
    require_manager(conn, opts, approved?, role)
  end

  # If the user is a manager, then they have access.
  defp require_manager(conn, _opts, true, :manager), do: conn

  # If the user is not a manager, then they don't have access.
  defp require_manager(_conn, _opts, _approved?, _role), do: raise(ZoonkWeb.PermissionError, code: :require_manager)

  @doc """
  Requires `manager` or `teacher` permissions to access a certain route.

  School routes require a manager but course routes also allow teachers to access them.
  """
  @spec require_manager_or_teacher(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def require_manager_or_teacher(%Plug.Conn{params: %{"course_slug" => _slug}} = conn, _opts) do
    %{school_user: school_user, course_user: course_user} = conn.assigns
    require_manager_or_course_teacher(conn, school_user, course_user)
  end

  def require_manager_or_teacher(conn, opts) do
    %{school_user: school_user} = conn.assigns
    require_manager_or_teacher(conn, opts, school_user.approved?, school_user.role)
  end

  # If the user is a manager or teacher, then they have access.
  defp require_manager_or_teacher(conn, _opts, true, :manager), do: conn
  defp require_manager_or_teacher(conn, _opts, true, :teacher), do: conn

  # If the user is not a manager or teacher, then they don't have access.
  defp require_manager_or_teacher(_conn, _opts, _approved?, _role), do: raise(ZoonkWeb.PermissionError, code: :require_manager_or_teacher)

  defp require_manager_or_course_teacher(conn, %{role: :manager, approved?: true}, _cu), do: conn
  defp require_manager_or_course_teacher(conn, _su, %{role: :teacher, approved?: true}), do: conn
  defp require_manager_or_course_teacher(_conn, _su, _cu), do: raise(ZoonkWeb.PermissionError, code: :require_manager_or_teacher)

  @doc """
  Handles mounting the school data to a LiveView.

  ## `on_mount` options

    * `:mount_school` - Mounts the school from the `school_username` param and the `host`.
  """
  @spec on_mount(atom(), LiveView.unsigned_params(), map(), Socket.t()) :: {:cont, Socket.t()}
  def on_mount(:mount_school, params, _session, socket) do
    %URI{host: host} = LiveView.get_connect_info(socket, :uri)
    school = get_school_from_socket(params, host)
    app = Organizations.get_app_school!(school)
    user = Map.get(socket.assigns, :current_user, nil)
    school_user = get_school_user(school, user)

    user_approved? = if is_map(school_user), do: school_user.approved?, else: false
    user_role = if user_approved?, do: school_user.role

    socket =
      socket
      |> Phoenix.Component.assign(host: host)
      |> Phoenix.Component.assign(app: app)
      |> Phoenix.Component.assign(school: school)
      |> Phoenix.Component.assign(school_user: school_user)
      |> Phoenix.Component.assign(user_role: user_role)
      |> Phoenix.Component.assign_new(:course, fn -> nil end)
      |> Phoenix.Component.assign_new(:lessons, fn -> nil end)
      |> Phoenix.Component.assign_new(:lesson, fn -> nil end)
      |> Phoenix.Component.assign_new(:first_lesson_id, fn -> nil end)
      |> Phoenix.Component.assign_new(:last_course_slug, fn -> nil end)

    {:cont, socket}
  end

  defp get_school_user(_school, nil), do: nil
  defp get_school_user(nil, _user), do: nil
  defp get_school_user(school, user), do: Organizations.get_school_user(school.slug, user.username)

  defp get_school(%{params: %{"school_slug" => slug}}), do: Organizations.get_school_by_slug!(slug)
  defp get_school(conn), do: Organizations.get_school_by_host!(conn.host)

  defp get_school_from_socket(%{"school_slug" => slug}, _host), do: Organizations.get_school_by_slug!(slug)
  defp get_school_from_socket(_params, host), do: Organizations.get_school_by_host!(host)
end
