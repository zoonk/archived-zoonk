defmodule UneebeeWeb.Plugs.School do
  @moduledoc """
  This is a multi-tenant app where we assign schools depending on the `host` value.

  ### Examples

  - `uneebee.com` -> `uneebee` school
  - `davinci.uneebee.com` -> `davinci` school using the slug as the subdomain
  - `interactive.harvard.edu` -> `harvard` school using a custom domain

  This means we need to fetch the app school's data when starting this application.
  """
  use UneebeeWeb, :verified_routes

  import Plug.Conn

  alias Phoenix.Controller
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket
  alias Uneebee.Organizations

  @doc """
  Fetches the school's data from the database.
  """
  @spec fetch_school(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def fetch_school(conn, _opts) do
    school = get_school(conn)
    school_user = get_school_user(school, conn.assigns.current_user)
    conn |> assign(:school, school) |> assign(:school_user, school_user)
  end

  @doc """
  Checks if the school is already configured.

  If so, then we don't want to show the configuration page.
  """
  @spec check_school_setup(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def check_school_setup(%{request_path: "/schools/new"} = conn, opts),
    do: check_school_setup(conn, opts, is_nil(conn.assigns.school))

  def check_school_setup(conn, _opts), do: conn

  # If the school is already configured, we don't want to show the configuration page.
  defp check_school_setup(_conn, _opts, false), do: raise(UneebeeWeb.PermissionError, code: :school_already_configured)
  defp check_school_setup(conn, _opts, true), do: conn

  @doc """
  Redirect to the setup page if the school isn't configured.
  """
  @spec setup_school(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def setup_school(%{request_path: "/"} = conn, opts), do: setup_school(conn, opts, is_nil(conn.assigns.school))
  def setup_school(conn, _opts), do: conn

  defp setup_school(conn, _opts, false), do: conn
  defp setup_school(conn, _opts, true), do: conn |> Controller.redirect(to: ~p"/schools/new") |> halt()

  @doc """
  Requires `manager` permissions to access a certain route.
  """
  @spec require_manager(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def require_manager(conn, opts) do
    %{school_user: school_user} = conn.assigns
    approved? = if school_user, do: school_user.approved?, else: false
    role = if school_user, do: school_user.role, else: nil
    require_manager(conn, opts, approved?, role)
  end

  # If the user is a manager, then they have access.
  defp require_manager(conn, _opts, true, :manager), do: conn

  # If the user is not a manager, then they don't have access.
  defp require_manager(_conn, _opts, _approved?, _role), do: raise(UneebeeWeb.PermissionError, code: :require_manager)

  @doc """
  Handles mounting the school data to a LiveView.

  ## `on_mount` options

    * `:mount_school` - Mounts the school from the `school_username` param and the `host`.
  """
  @spec on_mount(atom(), LiveView.unsigned_params(), map(), Socket.t()) :: {:cont, Socket.t()}
  def on_mount(:mount_school, params, _session, socket) do
    %URI{host: host} = LiveView.get_connect_info(socket, :uri)
    school = get_school_from_socket(params, host)
    host_school = Organizations.get_school_by_host!(host)
    user = Map.get(socket.assigns, :current_user, nil)
    school_user = get_school_user(school, user)

    user_approved? = if is_map(school_user), do: school_user.approved?, else: false
    user_role = if user_approved?, do: school_user.role, else: nil

    socket =
      socket
      |> Phoenix.Component.assign(host: host)
      |> Phoenix.Component.assign(host_school: host_school)
      |> Phoenix.Component.assign(school: school)
      |> Phoenix.Component.assign(school_user: school_user)
      |> Phoenix.Component.assign(user_role: user_role)

    {:cont, socket}
  end

  defp get_school_user(_school, nil), do: nil
  defp get_school_user(nil, _user), do: nil

  defp get_school_user(school, user), do: Organizations.get_school_user_by_slug_and_username(school.slug, user.username)

  defp get_school(%{params: %{"school_slug" => slug}}) do
    Organizations.get_school_by_slug!(slug)
  end

  defp get_school(conn), do: Organizations.get_school_by_host!(conn.host)

  defp get_school_from_socket(%{"school_slug" => slug}, _host), do: Organizations.get_school_by_slug!(slug)

  defp get_school_from_socket(_params, host), do: Organizations.get_school_by_host!(host)
end
