# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule UneebeeWeb.Components.Dashboard.UserListHeader do
  @moduledoc false
  use UneebeeWeb, :html

  attr :title, :string, required: true
  attr :course?, :boolean, default: false
  attr :count, :integer, required: true
  attr :add_user_label, :string, required: true
  attr :on_add_user, :any, required: true
  attr :search_link, :string, default: nil

  def user_list_header(assigns) do
    ~H"""
    <div class={[
      "sticky z-40 flex flex-wrap items-center gap-2 bg-gray-50 p-4 sm:flex-nowrap sm:px-6 lg:px-8",
      @course? && "top-[132px] sm:top-[128px]",
      !@course? && "top-[57px]"
    ]}>
      <h1 class="text-base font-semibold leading-7 text-gray-900"><%= @title %></h1>
      <.badge color={:info}><%= @count %></.badge>

      <.live_component :if={@search_link} id={:search_users} module={UneebeeWeb.Components.SearchButton} patch={@search_link} class="ml-auto" />

      <.button phx-click={@on_add_user} icon="tabler-user-plus" hide_label_on_mobile><%= @add_user_label %></.button>
    </div>
    """
  end
end
