defmodule UneebeeWeb.Router do
  use UneebeeWeb, :router

  import UneebeeWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {UneebeeWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers, %{"content-security-policy" => "default-src 'self'"}
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", UneebeeWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  ## Authentication routes
  scope "/", UneebeeWeb.Live.Accounts.User do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{UneebeeWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", Registration, :new
      live "/users/log_in", Login, :new
      live "/users/reset_password", ForgotPassword, :new
      live "/users/reset_password/:token", ResetPassword, :edit
    end
  end

  scope "/", UneebeeWeb.Live.Accounts.User do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{UneebeeWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", Settings, :edit
      live "/users/settings/confirm_email/:token", Settings, :confirm_email
    end
  end

  scope "/", UneebeeWeb.Live.Accounts.User do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{UneebeeWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", Confirmation, :edit
      live "/users/confirm", ConfirmationInstructions, :new
    end
  end

  scope "/", UneebeeWeb.Controller.Accounts.User do
    pipe_through [:browser, :redirect_if_user_is_authenticated]
    post "/users/log_in", Session, :create
  end

  scope "/", UneebeeWeb.Controller.Accounts.User do
    pipe_through [:browser]
    delete "/users/log_out", Session, :delete
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

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: UneebeeWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
