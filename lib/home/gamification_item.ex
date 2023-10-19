# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Home.GamificationItem do
  @moduledoc false
  use UneebeeWeb, :html

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :count, :string, required: true
  attr :icon, :string, required: true

  def gamification_item(assigns) do
    ~H"""
    <span class="text-primary-dark2x flex items-center gap-1 font-black" id={@id}>
      <.icon name={@icon} title={@title} /> <%= @count %>
    </span>
    """
  end
end
