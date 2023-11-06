# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule UneebeeWeb.Components.Dashboard.UserListHeader do
  @moduledoc false
  use UneebeeWeb, :html

  def user_list_header(assigns) do
    ~H"""
    <div class="flex flex-wrap items-center gap-2 bg-gray-50 p-4 sm:flex-nowrap sm:px-6 lg:px-8">
      <h1 class="text-base font-semibold leading-7 text-gray-900"><%= @title %></h1>
      <.badge color={:info}><%= @count %></.badge>
      <.button phx-click={@on_add_user} icon="tabler-user-plus" class="ml-auto"><%= @add_user_label %></.button>
    </div>
    """
  end
end
