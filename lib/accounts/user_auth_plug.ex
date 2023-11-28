defmodule UneebeeWeb.Plugs.UserAuth do
  @moduledoc false
  use UneebeeWeb, :verified_routes

  import Phoenix.Controller
  import Plug.Conn
  import UneebeeWeb.Gettext

  alias Phoenix.Component
  alias Phoenix.LiveView
  alias Phoenix.Socket
  alias Uneebee.Accounts
  alias Uneebee.Accounts.User
  alias Uneebee.Gamification
  alias Uneebee.Gamification.MissionUtils
  alias Uneebee.Organizations.School

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in UserToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_uneebee_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  @spec log_in_user(Plug.Conn.t(), User.t(), map()) :: Plug.Conn.t()
  def log_in_user(conn, user, params \\ %{}) do
    token = Accounts.generate_user_session_token(user)
    user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_token_in_session(token)
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: user_return_to || signed_in_path(conn))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  # This function renews the session ID and erases the whole
  # session to avoid fixation attacks. If there is any data
  # in the session you may want to preserve after log in/log out,
  # you must explicitly fetch the session data before clearing
  # and then immediately set it after clearing, for example:
  #
  #     defp renew_session(conn) do
  #       preferred_locale = get_session(conn, :preferred_locale)
  #
  #       conn
  #       |> configure_session(renew: true)
  #       |> clear_session()
  #       |> put_session(:preferred_locale, preferred_locale)
  #     end
  #
  defp renew_session(conn) do
    conn |> configure_session(renew: true) |> clear_session()
  end

  @doc """
  Logs the user out.

  It clears all session data for safety. See renew_session.
  """
  @spec log_out_user(Plug.Conn.t()) :: Plug.Conn.t()
  def log_out_user(conn) do
    user_token = get_session(conn, :user_token)
    user_token && Accounts.delete_user_session_token(user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      UneebeeWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: ~p"/users/login")
  end

  @doc """
  Authenticates the user by looking into the session
  and remember me token.
  """
  @spec fetch_current_user(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = user_token && Accounts.get_user_by_session_token(user_token)
    username = if user, do: user.username

    Sentry.Context.set_user_context(%{username: username})
    Sentry.Context.set_request_context(%{url: conn.request_path})

    assign(conn, :current_user, user)
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if token = conn.cookies[@remember_me_cookie] do
        {token, put_token_in_session(conn, token)}
      else
        {nil, conn}
      end
    end
  end

  @doc """
  Handles mounting and authenticating the current_user in LiveViews.

  ## `on_mount` arguments

    * `:mount_current_user` - Assigns current_user
      to socket assigns based on user_token, or nil if
      there's no user_token or no matching user.

    * `:ensure_authenticated` - Authenticates the user from the session,
      and assigns the current_user to socket assigns based
      on user_token.
      Redirects to login page if there's no logged user.

    * `:redirect_if_user_is_authenticated` - Authenticates the user from the session.
      Redirects to signed_in_path if there's a logged user.

  ## Examples

  Use the `on_mount` lifecycle macro in LiveViews to mount or authenticate
  the current_user:

      defmodule UneebeeWeb.PageLive do
        use UneebeeWeb, :live_view

        on_mount {UneebeeWeb.Plugs.UserAuth, :mount_current_user}
        ...
      end

  Or use the `live_session` of your router to invoke the on_mount callback:

      live_session :authenticated, on_mount: [{UneebeeWeb.Plugs.UserAuth, :ensure_authenticated}] do
        live "/profile", ProfileLive, :index
      end
  """
  @spec on_mount(atom(), LiveView.unsigned_params(), map(), Socket.t()) :: {:cont, Socket.t()} | {:halt, Socket.t()}
  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        |> Phoenix.LiveView.put_flash(:error, dgettext("auth", "You must log in to access this page."))
        |> Phoenix.LiveView.redirect(to: ~p"/users/login")

      {:halt, socket}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp mount_current_user(socket, session) do
    user = get_user_by_session_token(session)
    learning_days = get_learning_days(user)
    medals = get_user_medals(user)
    trophies = get_user_trophies(user)
    mission_progress = mission_progress(user)

    socket
    |> Component.assign_new(:current_user, fn -> user end)
    |> Component.assign(:learning_days, learning_days)
    |> Component.assign(:medals, medals)
    |> Component.assign(:trophies, trophies)
    |> Component.assign(:mission_progress, mission_progress)
  end

  defp get_user_by_session_token(session) do
    if user_token = session["user_token"] do
      Accounts.get_user_by_session_token(user_token)
    end
  end

  defp get_learning_days(nil), do: nil
  defp get_learning_days(user), do: Gamification.learning_days_count(user.id)

  defp get_user_medals(nil), do: nil
  defp get_user_medals(user), do: Gamification.count_user_medals(user.id)

  defp get_user_trophies(nil), do: nil
  defp get_user_trophies(user), do: Gamification.count_user_trophies(user.id)

  defp get_user_missions(user), do: Gamification.count_completed_missions(user.id)

  defp mission_progress(nil), do: 0
  defp mission_progress(user), do: user |> get_user_missions() |> Kernel./(supported_missions_count()) |> Kernel.*(100) |> round()

  defp supported_missions_count, do: length(MissionUtils.supported_missions())

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  @spec redirect_if_user_is_authenticated(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn |> redirect(to: signed_in_path(conn)) |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  @spec require_authenticated_user(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def require_authenticated_user(%Plug.Conn{assigns: %{current_user: %User{guest?: true}, school: %School{allow_guests?: false}}} = conn, _opts) do
    conn |> log_out_user() |> halt()
  end

  def require_authenticated_user(%Plug.Conn{assigns: %{current_user: user}} = conn, _opts) when not is_nil(user), do: conn
  def require_authenticated_user(%Plug.Conn{request_path: "/dashboard" <> _rest} = conn, _opts), do: redirect_to_login(conn)

  def require_authenticated_user(%Plug.Conn{assigns: %{school: %School{allow_guests?: true}}} = conn, _opts) do
    {:ok, %User{} = user} = Accounts.create_guest_user()
    conn |> put_session(:user_return_to, conn.request_path) |> log_in_user(user, %{"remember_me" => "true"}) |> halt()
  end

  def require_authenticated_user(conn, _opts), do: redirect_to_login(conn)

  defp redirect_to_login(conn) do
    conn
    |> put_flash(:error, dgettext("auth", "You must log in to access this page."))
    |> maybe_store_return_to()
    |> redirect(to: ~p"/users/login")
    |> halt()
  end

  defp put_token_in_session(conn, token) do
    encoded_token = Base.url_encode64(token)

    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{encoded_token}")
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: ~p"/"
end
