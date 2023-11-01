# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule UneebeeWeb.Components.Layouts.MenuMobile do
  @moduledoc false
  use UneebeeWeb, :html

  import UneebeeWeb.Components.Layouts.GamificationMenu
  import UneebeeWeb.Layouts.MenuUtils

  alias Uneebee.Content.CourseUtils

  attr :active_page, :atom, default: nil
  attr :learning_days, :integer, required: true
  attr :mission_progress, :integer, required: true
  attr :trophies, :integer, required: true
  attr :medals, :integer, required: true
  attr :lessons, :list, default: nil
  attr :user_role, :atom, default: nil

  def menu_mobile(assigns) do
    ~H"""
    <header :if={show_menu?(@active_page)} class="sticky top-0 z-50 w-full bg-white p-4 shadow lg:hidden">
      <nav class="m-auto flex max-w-3xl justify-around">
        <.gamification_menu view={:mobile} learning_days={@learning_days} mission_progress={@mission_progress} trophies={@trophies} medals={@medals} />
      </nav>

      <div :if={@lessons && not dashboard?(@active_page)} class="m-auto mt-4 max-w-3xl">
        <.progress total={length(@lessons)} current={CourseUtils.completed_lessons_count(@lessons)} />
      </div>
    </header>

    <nav :if={show_menu?(@active_page)} class="bg-white/90 fixed right-4 bottom-4 left-4 z-50 rounded-2xl p-2 shadow backdrop-blur-sm lg:hidden">
      <ul class="m-auto flex max-w-3xl justify-around gap-2">
        <.menu_bottom_item color={:primary} active={@active_page == :courseview} icon="tabler-home-2" label={gettext("Home")} href={~p"/"} />

        <.menu_bottom_item
          :if={@user_role != :manager}
          color={:warning}
          active={@active_page == :mycourses}
          icon="tabler-books"
          label={gettext("My courses")}
          href={~p"/courses/my"}
        />

        <.menu_bottom_item color={:success} active={@active_page == :courselist} icon="tabler-ufo" label={gettext("Courses")} navigate={~p"/courses"} />

        <.menu_bottom_item
          :if={@user_role == :manager}
          color={:alert}
          active={dashboard?(@active_page) and not course?(@active_page) and not lesson_view?(@active_page)}
          icon="tabler-table"
          label={dgettext("orgs", "Manage school")}
          href={~p"/dashboard"}
        />

        <.menu_bottom_item
          :if={@user_role in [:manager, :teacher]}
          color={:bronze}
          active={course?(@active_page) or lesson_view?(@active_page)}
          icon="tabler-table-column"
          label={dgettext("orgs", "Manage courses")}
          href={~p"/dashboard/courses"}
        />

        <.menu_bottom_item
          color={:info}
          active={@active_page == :usersettingsmenu or user_settings?(@active_page)}
          icon="tabler-settings-2"
          label={gettext("Settings")}
          navigate={~p"/users/settings"}
        />
      </ul>
    </nav>
    """
  end

  attr :active, :boolean, default: false
  attr :color, :atom, values: [:alert, :primary, :info, :success, :warning, :gray, :bronze], required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :rest, :global, include: ~w(href method navigate patch)

  defp menu_bottom_item(assigns) do
    ~H"""
    <li class={["rounded-2xl p-2", @active && "text-primary", not @active && "text-gray"]} title={@label} aria-current={@active and "page"}>
      <.link {@rest}>
        <.icon name={@icon} title={@label} class="h-6 w-6" />
      </.link>
    </li>
    """
  end
end
