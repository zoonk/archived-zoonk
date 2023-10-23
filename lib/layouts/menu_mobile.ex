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
    <header class="sticky top-0 w-full bg-white p-4 shadow lg:hidden">
      <nav class="m-auto flex max-w-3xl justify-between">
        <.gamification_menu learning_days={@learning_days} mission_progress={@mission_progress} trophies={@trophies} medals={@medals} />
      </nav>

      <div :if={@lessons} class="m-auto mt-4 max-w-3xl">
        <.progress total={length(@lessons)} current={CourseUtils.completed_lessons_count(@lessons)} />
      </div>
    </header>

    <nav class="border-gray-light fixed right-0 bottom-0 left-0 border-t-2 bg-white p-2 lg:hidden">
      <ul class="m-auto flex max-w-3xl justify-between gap-2">
        <.menu_bottom_item color={:primary} active={@active_page == :courseview} icon="tabler-home-2" label={gettext("Home")} href={~p"/"} />
        <.menu_bottom_item color={:warning} active={@active_page == :mycourses} icon="tabler-books" label={gettext("My courses")} href={~p"/courses/my"} />
        <.menu_bottom_item color={:success} active={@active_page == :courselist} icon="tabler-ufo" label={gettext("Courses")} navigate={~p"/courses"} />

        <.menu_bottom_item
          :if={@user_role in [:manager, :teacher]}
          color={:alert}
          active={dashboard?(@active_page)}
          icon="tabler-table"
          label={gettext("Dashboard")}
          href={~p"/dashboard"}
        />

        <.menu_bottom_item color={:info} active={user_settings?(@active_page)} icon="tabler-settings" label={gettext("Settings")} navigate={~p"/users/settings/language"} />
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
    <li
      class={[
        "rounded-2xl p-2",
        @active && "bg-gray-light3x",
        not @active && "bg-white",
        @color == :alert && "text-alert",
        @color == :primary && "text-primary",
        @color == :info && "text-info",
        @color == :success && "text-success",
        @color == :warning && "text-warning",
        @color == :gray && "text-gray",
        @color == :bronze && "text-bronze"
      ]}
      title={@label}
      aria-current={@active and "page"}
    >
      <.link {@rest}>
        <.icon name={@icon} title={@label} class="h-10 w-10" />
      </.link>
    </li>
    """
  end
end
