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
            <.menu_item href={~p"/"} icon="tabler-home-2" active={home_page?(@active_page, @course, @last_course_slug)} title={gettext("Home")} />
            <.menu_item navigate={~p"/courses/my"} icon="tabler-books" active={@active_page == :mycourses} title={gettext("My courses")} />

            <.menu_item
              navigate={~p"/courses"}
              icon="tabler-ufo"
              active={@active_page == :courselist or (@active_page == :courseview and not home_page?(@active_page, @course, @last_course_slug))}
              title={gettext("Courses")}
            />

            <.menu_item :if={@app && @app.kind in [:saas, :marketplace]} navigate={~p"/schools/new"} icon="tabler-rocket" title={gettext("Create school")} />
          </ul>
        </li>

        <li :if={@user_role in [:manager, :teacher]}>
          <div class="text-xs font-semibold leading-6 text-gray-400"><%= dgettext("orgs", "Dashboard") %></div>

          <ul role="list" class="-mx-2 mt-2 space-y-1">
            <.menu_item :if={@user_role == :manager} href={~p"/dashboard"} icon="tabler-table" active={dashboard_school?(@active_page)} title={dgettext("orgs", "Manage school")} />
            <.menu_item href={~p"/dashboard/courses"} icon="tabler-table-column" active={dashboard_course?(@active_page)} title={dgettext("orgs", "Manage courses")} />
          </ul>
        </li>

        <li class="mt-auto">
          <ul class="-mx-2 space-y-1">
            <.menu_item navigate={~p"/feedback"} icon="tabler-message-circle-2" active={@active_page == :feedback} title={gettext("Feedback")} />
            <.menu_item navigate={~p"/users/settings"} icon="tabler-settings" active={user_settings?(@active_page)} title={gettext("Settings")} />
          </ul>
        </li>
      </ul>
    </nav>
    """
  end
end
