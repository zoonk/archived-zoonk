# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule UneebeeWeb.Components.Layouts.AppMenu do
  @moduledoc false
  use UneebeeWeb, :html

  import UneebeeWeb.Layouts.MenuUtils

  def app_menu(assigns) do
    ~H"""
    <nav class="flex flex-1 flex-col">
      <ul role="list" class="flex flex-1 flex-col gap-y-7">
        <li>
          <ul role="list" class="-mx-2 space-y-1">
            <.menu_item href={~p"/"} icon="tabler-home-2" active={@active_page == :courseview} title={gettext("Home")} />
            <.menu_item href={~p"/courses/my"} icon="tabler-books" active={@active_page == :mycourses} title={gettext("My courses")} />
            <.menu_item href={~p"/courses"} icon="tabler-ufo" active={@active_page == :courselist} title={gettext("Courses")} />
          </ul>
        </li>

        <li :if={@user_role == :manager}>
          <div class="text-xs font-semibold leading-6 text-gray-400"><%= dgettext("orgs", "Manage school") %></div>

          <ul role="list" class="-mx-2 mt-2 space-y-1">
            <.menu_item href={~p"/dashboard"} active={@active_page == :dashboard_home} title={gettext("Overview")} />

            <div :if={school_expanded?(@active_page)}>
              <.menu_item href={~p"/dashboard/managers"} active={@active_page == :dashboard_userlist_manager} title={gettext("Managers")} />
              <.menu_item href={~p"/dashboard/teachers"} active={@active_page == :dashboard_userlist_teacher} title={gettext("Teachers")} />
              <.menu_item href={~p"/dashboard/students"} active={@active_page == :dashboard_userlist_student} title={gettext("Students")} />
              <.menu_item href={~p"/dashboard/edit/logo"} active={@active_page == :dashboard_schooledit_logo} title={gettext("Logo")} />
              <.menu_item href={~p"/dashboard/edit/slug"} active={@active_page == :dashboard_schooledit_slug} title={dgettext("orgs", "Nickname")} />
              <.menu_item href={~p"/dashboard/edit/info"} active={@active_page == :dashboard_schooledit_info} title={gettext("Profile")} />
              <.menu_item href={~p"/dashboard/edit/terms"} active={@active_page == :dashboard_schooledit_terms} title={dgettext("orgs", "Terms of use")} />
            </div>
          </ul>
        </li>

        <li :if={@user_role in [:manager, :teacher]}>
          <div class="text-xs font-semibold leading-6 text-gray-400"><%= dgettext("orgs", "Manage courses") %></div>

          <ul role="list" class="-mx-2 mt-2 space-y-1">
            <.menu_item :if={not course_view?(@active_page)} href={~p"/dashboard/courses"} title={dgettext("orgs", "All courses")} />
            <.menu_item navigate={~p"/dashboard/courses/new"} active={@active_page == :dashboard_coursenew} title={gettext("Create a course")} />

            <div :if={course_view?(@active_page)}>
              <.menu_item navigate={~p"/dashboard/c/#{@course.slug}"} active={@active_page == :dashboard_courseview} title={dgettext("orgs", "Course page")} />

              <.menu_item
                navigate={~p"/dashboard/c/#{@course.slug}/l/#{@first_lesson_id}/s/1"}
                active={@active_page == :dashboard_lessonview}
                title={dgettext("orgs", "Lesson editor")}
              />

              <.menu_item
                navigate={~p"/dashboard/c/#{@course.slug}/students"}
                active={@active_page in [:dashboard_courseuserlist_student, :dashboard_coursestudentview]}
                title={gettext("Students")}
              />

              <.menu_item navigate={~p"/dashboard/c/#{@course.slug}/teachers"} active={@active_page == :dashboard_courseuserlist_teacher} title={gettext("Teachers")} />
              <.menu_item navigate={~p"/dashboard/c/#{@course.slug}/edit/info"} active={@active_page == :dashboard_courseedit_info} title={gettext("Information")} />
              <.menu_item navigate={~p"/dashboard/c/#{@course.slug}/edit/cover"} active={@active_page == :dashboard_courseedit_cover} title={gettext("Cover")} />
              <.menu_item navigate={~p"/dashboard/c/#{@course.slug}/edit/privacy"} active={@active_page == :dashboard_courseedit_privacy} title={gettext("Privacy")} />

              <.menu_item
                navigate={~p"/dashboard/c/#{@course.slug}/edit/delete"}
                active={@active_page == :dashboard_courseedit_delete}
                title={dgettext("courses", "Delete course")}
              />
            </div>
          </ul>
        </li>

        <li class="mt-auto">
          <ul class="-mx-2 space-y-1">
            <.menu_item href={~p"/feedback"} icon="tabler-message-circle-2" active={@active_page == :feedback} title={gettext("Feedback")} />
            <.menu_item href={~p"/users/settings/language"} icon="tabler-settings" active={user_settings?(@active_page)} title={gettext("Settings")} />
          </ul>
        </li>
      </ul>
    </nav>
    """
  end
end
