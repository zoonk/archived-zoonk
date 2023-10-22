defmodule UneebeeWeb.Router do
  use UneebeeWeb, :router

  import UneebeeWeb.Plugs.Course
  import UneebeeWeb.Plugs.School
  import UneebeeWeb.Plugs.Translate
  import UneebeeWeb.Plugs.UserAuth

  @nonce 10 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
  @csp_connect_src Application.compile_env(:uneebee, :csp)[:connect_src]
  @cdn_url Application.compile_env(:uneebee, :cdn)[:url]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {UneebeeWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers, %{"content-security-policy" => "default-src 'self'; connect-src 'self' #{@csp_connect_src}; img-src 'self' #{@cdn_url} data: blob:;"}
    plug :fetch_current_user
    plug :fetch_school
    plug :check_school_setup
    plug :setup_school
    plug :set_session_locale
  end

  pipeline :dev_dashboard do
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
  scope "/", UneebeeWeb.Live do
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

  scope "/", UneebeeWeb.Live do
    pipe_through [:browser]

    live_session :public_routes,
      layout: {UneebeeWeb.Layouts, :auth},
      on_mount: [
        {UneebeeWeb.Plugs.UserAuth, :mount_current_user},
        {UneebeeWeb.Plugs.School, :mount_school},
        {UneebeeWeb.Plugs.Translate, :set_locale_from_session}
      ] do
      live "/users/confirm/:token", UserConfirmation, :edit
      live "/users/confirm", ConfirmationInstructions, :new
    end
  end

  scope "/", UneebeeWeb.Live do
    pipe_through [:browser, :require_authenticated_user, :require_subscription_for_private_schools, :fetch_course, :require_course_user_for_lesson]

    live_session :requires_authentication,
      on_mount: [
        {UneebeeWeb.Plugs.UserAuth, :ensure_authenticated},
        {UneebeeWeb.Plugs.School, :mount_school},
        {UneebeeWeb.Plugs.Translate, :set_locale_from_session},
        {UneebeeWeb.Plugs.Course, :mount_course},
        {UneebeeWeb.Plugs.Course, :mount_lesson},
        UneebeeWeb.Plugs.ActivePage
      ] do
      live "/", Home
      live "/feedback", Feedback

      live "/missions", MissionList
      live "/trophies", TrophyList
      live "/medals", MedalList

      live "/users/settings/email", UserSettings, :email
      live "/users/settings/language", UserSettings, :language
      live "/users/settings/name", UserSettings, :name
      live "/users/settings/password", UserSettings, :password
      live "/users/settings/username", UserSettings, :username
      live "/users/settings/confirm_email/:token", UserSettings, :confirm_email

      live "/schools/new", SchoolNew

      live "/courses", CourseList
      live "/c/:course_slug", CourseView
      live "/c/:course_slug/:lesson_id", LessonPlay
      live "/c/:course_slug/:lesson_id/completed", LessonCompleted
    end
  end

  scope "/", UneebeeWeb.Controller do
    pipe_through [:browser, :redirect_if_user_is_authenticated]
    post "/users/login", UserSession, :create
  end

  scope "/", UneebeeWeb.Controller do
    pipe_through [:browser]
    delete "/users/logout", UserSession, :delete
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
      live "/edit/terms", Dashboard.SchoolEdit, :terms

      live "/managers", Dashboard.UserList, :manager
      live "/teachers", Dashboard.UserList, :teacher
      live "/students", Dashboard.UserList, :student
    end
  end

  # These routes are only available to managers and teachers.
  scope "/dashboard", UneebeeWeb.Live.Dashboard do
    pipe_through [:browser, :require_authenticated_user, :fetch_course, :require_manager_or_teacher]

    live_session :course_dashboard,
      on_mount: [
        {UneebeeWeb.Plugs.UserAuth, :ensure_authenticated},
        {UneebeeWeb.Plugs.School, :mount_school},
        {UneebeeWeb.Plugs.Translate, :set_locale_from_session},
        {UneebeeWeb.Plugs.Course, :mount_course},
        {UneebeeWeb.Plugs.Course, :mount_lesson},
        UneebeeWeb.Plugs.ActivePage
      ] do
      live "/courses", CourseList
      live "/courses/new", CourseNew

      live "/c/:course_slug", CourseView
      live "/c/:course_slug/edit/cover", CourseEdit, :cover
      live "/c/:course_slug/edit/info", CourseEdit, :info
      live "/c/:course_slug/edit/privacy", CourseEdit, :privacy
      live "/c/:course_slug/edit/delete", CourseEdit, :delete

      live "/c/:course_slug/teachers", CourseUserList, :teacher
      live "/c/:course_slug/students", CourseUserList, :student
      live "/c/:course_slug/s/:username", CourseStudentView

      live "/c/:course_slug/l/:lesson_id/s/:step_order", LessonView
      live "/c/:course_slug/l/:lesson_id/s/:step_order/edit", LessonView, :edit
      live "/c/:course_slug/l/:lesson_id/s/:step_order/image", LessonView, :step_img
      live "/c/:course_slug/l/:lesson_id/s/:step_order/o/:option_id", LessonView, :option
      live "/c/:course_slug/l/:lesson_id/s/:step_order/o/:option_id/image", LessonView, :option_img

      live "/c/:course_slug/l/:lesson_id/info", LessonEdit
      live "/c/:course_slug/l/:lesson_id/cover", LessonCover
      live "/c/:course_slug/l/:lesson_id/delete", LessonDelete
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
      pipe_through :dev_dashboard
      live_dashboard "/", metrics: UneebeeWeb.Telemetry, csp_nonce_assign_key: :csp_nonce
    end

    scope "/dev/mailbox" do
      pipe_through :mailbox
      forward "/", Plug.Swoosh.MailboxPreview
    end
  end
end
