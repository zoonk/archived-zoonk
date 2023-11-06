# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule UneebeeWeb.Components.Layouts.UserMenu do
  @moduledoc false
  use UneebeeWeb, :html

  import UneebeeWeb.Components.Layouts.DashboardMenuItem

  def user_menu(assigns) do
    ~H"""
    <nav class="border-gray-900/10 sticky top-0 z-40 w-full border-b bg-white">
      <ul role="list" class="border-gray-900/10 flex min-w-full flex-none gap-x-6 overflow-x-auto p-4 text-sm font-semibold leading-6 text-gray-400 sm:px-6 lg:px-8">
        <li class="lg:hidden">
          <.link href={~p"/"}><%= gettext("Home") %></.link>
        </li>

        <.dashboard_menu_item active={@active == :usersettings_profile} navigate={~p"/users/settings"}>
          <%= gettext("Profile") %>
        </.dashboard_menu_item>

        <.dashboard_menu_item active={@active == :usersettings_email} navigate={~p"/users/settings/email"}>
          <%= gettext("Email") %>
        </.dashboard_menu_item>

        <.dashboard_menu_item active={@active == :usersettings_password} navigate={~p"/users/settings/password"}>
          <%= gettext("Password") %>
        </.dashboard_menu_item>

        <.dashboard_menu_item method="delete" href={~p"/users/logout"}>
          <%= gettext("Logout") %>
        </.dashboard_menu_item>
      </ul>
    </nav>
    """
  end
end
