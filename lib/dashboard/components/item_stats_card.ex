# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule UneebeeWeb.Components.Dashboard.ItemStatsCard do
  @moduledoc false
  use UneebeeWeb, :html

  attr :title, :string, required: true
  attr :icon, :string, required: true
  attr :count, :integer, required: true

  def item_stats_card(assigns) do
    ~H"""
    <div class="flex items-center gap-1 rounded-2xl bg-white px-4 py-2 shadow">
      <.icon name={@icon} class="h-4 w-4" />
      <h3 class="text-gray-dark flex-1 truncate text-sm"><%= @title %></h3>
      <span class="text-gradient text-sm font-semibold"><%= @count %></span>
    </div>
    """
  end
end
