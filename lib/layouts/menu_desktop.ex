# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule UneebeeWeb.Components.Layouts.MenuDesktop do
  @moduledoc false
  use UneebeeWeb, :html

  import UneebeeWeb.Components.Layouts.GamificationMenu
  import UneebeeWeb.Layouts.MenuUtils

  def menu_desktop(assigns) do
    ~H"""
    <.menu :if={show_menu?(@active_page)}>
      <:header>
        <.gamification_menu view={:desktop} learning_days={@learning_days} mission_progress={@mission_progress} trophies={@trophies} medals={@medals} />
      </:header>

      <.menu_item href={~p"/"} icon="tabler-home-2" active={@active_page == :courseview} title={gettext("Home")} />

      <.menu_item
        :if={@user_role == :manager}
        href={~p"/dashboard"}
        icon="tabler-table"
        active={dashboard?(@active_page) and not course?(@active_page) and not lesson_view?(@active_page)}
        title={dgettext("orgs", "Manage school")}
      >
        <:sub_menus>
          <.sub_menu navigate={~p"/dashboard"} active={@active_page == :dashboard_home} title={gettext("Dashboard")} />
          <.sub_menu navigate={~p"/dashboard/managers"} active={@active_page == :dashboard_userlist_manager} title={gettext("Managers")} />
          <.sub_menu navigate={~p"/dashboard/teachers"} active={@active_page == :dashboard_userlist_teacher} title={gettext("Teachers")} />
          <.sub_menu navigate={~p"/dashboard/students"} active={@active_page == :dashboard_userlist_student} title={gettext("Students")} />
          <.sub_menu navigate={~p"/dashboard/edit/logo"} active={@active_page == :dashboard_schooledit_logo} title={gettext("Logo")} />
          <.sub_menu navigate={~p"/dashboard/edit/slug"} active={@active_page == :dashboard_schooledit_slug} title={dgettext("orgs", "Nickname")} />
          <.sub_menu navigate={~p"/dashboard/edit/info"} active={@active_page == :dashboard_schooledit_info} title={gettext("Profile")} />
          <.sub_menu navigate={~p"/dashboard/edit/terms"} active={@active_page == :dashboard_schooledit_terms} title={dgettext("orgs", "Terms of use")} />
        </:sub_menus>
      </.menu_item>

      <.menu_item
        :if={@user_role in [:manager, :teacher]}
        href={~p"/dashboard/courses"}
        icon="tabler-table-column"
        active={course?(@active_page)}
        title={dgettext("orgs", "Manage courses")}
      >
        <:sub_menus>
          <.sub_menu navigate={~p"/dashboard/courses"} active={@active_page == :dashboard_courselist} title={gettext("All courses")} />
          <.sub_menu navigate={~p"/dashboard/courses/new"} active={@active_page == :dashboard_coursenew} title={gettext("Create a course")} />

          <.sub_menu
            :if={course_view?(@active_page)}
            navigate={~p"/dashboard/c/#{@course.slug}"}
            active={@active_page == :dashboard_courseview}
            title={dgettext("courses", "Course page")}
          />

          <.sub_menu
            :if={course_view?(@active_page)}
            navigate={~p"/dashboard/c/#{@course.slug}/students"}
            active={@active_page in [:dashboard_courseuserlist_student, :dashboard_coursestudentview]}
            title={gettext("Students")}
          />

          <.sub_menu
            :if={course_view?(@active_page)}
            navigate={~p"/dashboard/c/#{@course.slug}/teachers"}
            active={@active_page == :dashboard_courseuserlist_teacher}
            title={gettext("Teachers")}
          />

          <.sub_menu
            :if={course_view?(@active_page)}
            navigate={~p"/dashboard/c/#{@course.slug}/edit/info"}
            active={@active_page == :dashboard_courseedit_info}
            title={gettext("Information")}
          />

          <.sub_menu
            :if={course_view?(@active_page)}
            navigate={~p"/dashboard/c/#{@course.slug}/edit/cover"}
            active={@active_page == :dashboard_courseedit_cover}
            title={gettext("Cover")}
          />

          <.sub_menu
            :if={course_view?(@active_page)}
            navigate={~p"/dashboard/c/#{@course.slug}/edit/privacy"}
            active={@active_page == :dashboard_courseedit_privacy}
            title={gettext("Privacy")}
          />

          <.sub_menu
            :if={course_view?(@active_page)}
            navigate={~p"/dashboard/c/#{@course.slug}/edit/delete"}
            active={@active_page == :dashboard_courseedit_delete}
            title={dgettext("courses", "Delete course")}
          />
        </:sub_menus>
      </.menu_item>

      <.menu_item
        :if={lesson_view?(@active_page)}
        navigate={~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/s/1"}
        icon="tabler-notes"
        active={lesson_view?(@active_page)}
        title={dgettext("courses", "Manage lesson")}
      >
        <:sub_menus>
          <.sub_menu :if={lesson_view?(@active_page)} navigate={~p"/dashboard/c/#{@course.slug}"} active={false} title={dgettext("courses", "All lessons")} />

          <.sub_menu
            :if={lesson_view?(@active_page)}
            navigate={~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/s/1"}
            active={@active_page == :dashboard_lessonview}
            title={dgettext("courses", "Content")}
          />

          <.sub_menu
            :if={lesson_view?(@active_page)}
            navigate={~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/info"}
            active={@active_page == :dashboard_lessonedit}
            title={dgettext("courses", "Information")}
          />

          <.sub_menu
            :if={lesson_view?(@active_page)}
            navigate={~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/cover"}
            active={@active_page == :dashboard_lessoncover}
            title={gettext("Cover")}
          />

          <.sub_menu
            :if={lesson_view?(@active_page)}
            navigate={~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/delete"}
            active={@active_page == :dashboard_lessondelete}
            title={dgettext("courses", "Delete lesson")}
          />
        </:sub_menus>
      </.menu_item>

      <.menu_item href={~p"/courses/my"} icon="tabler-books" active={@active_page == :mycourses} title={gettext("My courses")} />
      <.menu_item href={~p"/courses"} icon="tabler-ufo" active={@active_page == :courselist} title={gettext("Courses")} />
      <.menu_item href={~p"/feedback"} icon="tabler-message-circle-2" active={@active_page == :feedback} title={gettext("Feedback")} />

      <.menu_item href={~p"/users/settings/language"} icon="tabler-settings" active={user_settings?(@active_page)} title={gettext("Settings")}>
        <:sub_menus>
          <.sub_menu navigate={~p"/users/settings/language"} active={@active_page == :usersettings_language} title={gettext("Language")} />
          <.sub_menu navigate={~p"/users/settings/username"} active={@active_page == :usersettings_username} title={gettext("Username")} />
          <.sub_menu navigate={~p"/users/settings/name"} active={@active_page == :usersettings_name} title={gettext("Name")} />
          <.sub_menu navigate={~p"/users/settings/email"} active={@active_page == :usersettings_email} title={gettext("Email")} />
          <.sub_menu navigate={~p"/users/settings/password"} active={@active_page == :usersettings_password} title={dgettext("auth", "Password")} />
          <.sub_menu href={~p"/users/logout"} method="delete" title={gettext("Logout")} />
        </:sub_menus>
      </.menu_item>
    </.menu>
    """
  end
end
