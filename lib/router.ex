defmodule UneebeeWeb.Router do
  use UneebeeWeb, :router

  import UneebeeWeb.Plugs.School
  import UneebeeWeb.Plugs.Translate
  import UneebeeWeb.Plugs.UserAuth

  @nonce 10 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {UneebeeWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers, %{"content-security-policy" => "default-src 'self'; img-src 'self' data: blob:;"}
    plug :fetch_current_user
    plug :fetch_school
    plug :check_school_setup
    plug :setup_school
    plug :set_session_locale
  end

  pipeline :dashboard do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug UneebeeWeb.Plugs.CspNonce, nonce: @nonce
    plug :put_secure_browser_headers, %{"content-security-policy" => "style-src 'self' 'nonce-#{@nonce}'"}
  end

  pipeline :mailbox do
    plug :accepts, ["html"]
    plug :put_secure_browser_headers, %{"content-security-policy" => "style-src 'unsafe-inline'"}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  ## Authentication routes
  scope "/", UneebeeWeb.Live.Accounts.User do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      layout: {UneebeeWeb.Layouts, :auth},
      on_mount: [
        {UneebeeWeb.Plugs.UserAuth, :redirect_if_user_is_authenticated},
        {UneebeeWeb.Plugs.School, :mount_school},
        {UneebeeWeb.Plugs.Translate, :set_locale_from_session}
      ] do
      live "/users/register", Registration, :new
      live "/users/login", Login, :new
      live "/users/reset_password", ForgotPassword, :new
      live "/users/reset_password/:token", ResetPassword, :edit
    end
  end

  # Requires authentication
  scope "/", UneebeeWeb.Live do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [
        {UneebeeWeb.Plugs.UserAuth, :ensure_authenticated},
        {UneebeeWeb.Plugs.School, :mount_school},
        {UneebeeWeb.Plugs.Translate, :set_locale_from_session},
        UneebeeWeb.Plugs.ActivePage
      ] do
      live "/schools/new", Organizations.School.New

      live "/users/settings/email", Accounts.User.Settings, :email
      live "/users/settings/language", Accounts.User.Settings, :language
      live "/users/settings/name", Accounts.User.Settings, :name
      live "/users/settings/password", Accounts.User.Settings, :password
      live "/users/settings/username", Accounts.User.Settings, :username

      live "/users/settings/confirm_email/:token", Accounts.User.Settings, :confirm_email
    end
  end

  scope "/", UneebeeWeb.Live do
    pipe_through [:browser]

    live_session :public_routes,
      on_mount: [
        {UneebeeWeb.Plugs.UserAuth, :mount_current_user},
        {UneebeeWeb.Plugs.School, :mount_school},
        {UneebeeWeb.Plugs.Translate, :set_locale_from_session},
        UneebeeWeb.Plugs.ActivePage
      ] do
      live "/", Home

      live "/users/confirm/:token", Accounts.User.Confirmation, :edit
      live "/users/confirm", Accounts.User.ConfirmationInstructions, :new
    end
  end

  scope "/", UneebeeWeb.Controller.Accounts.User do
    pipe_through [:browser, :redirect_if_user_is_authenticated]
    post "/users/login", Session, :create
  end

  scope "/", UneebeeWeb.Controller.Accounts.User do
    pipe_through [:browser]
    delete "/users/logout", Session, :delete
  end

  # Routes visible to school managers only.
  scope "/dashboard", UneebeeWeb.Live do
    pipe_through [:browser, :require_authenticated_user, :require_manager]

    live_session :school_dashboard,
      on_mount: [
        {UneebeeWeb.Plugs.UserAuth, :ensure_authenticated},
        {UneebeeWeb.Plugs.School, :mount_school},
        {UneebeeWeb.Plugs.Translate, :set_locale_from_session},
        UneebeeWeb.Plugs.ActivePage
      ] do
      live "/", Dashboard.Home
      live "/edit/logo", Dashboard.SchoolEdit, :logo
      live "/edit/slug", Dashboard.SchoolEdit, :slug
      live "/edit/info", Dashboard.SchoolEdit, :info

      live "/managers", Dashboard.UserList, :manager
      live "/teachers", Dashboard.UserList, :teacher
      live "/students", Dashboard.UserList, :student
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", UneebeeWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:uneebee, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev/dashboard" do
      pipe_through :dashboard
      live_dashboard "/", metrics: UneebeeWeb.Telemetry, csp_nonce_assign_key: :csp_nonce_value
    end

    scope "/dev/mailbox" do
      pipe_through :mailbox
      forward "/", Plug.Swoosh.MailboxPreview
    end
  end
end
