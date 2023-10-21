# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Layouts.GamificationItem do
  @moduledoc false
  use UneebeeWeb, :html

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :count, :string, required: true
  attr :icon, :string, required: true
  attr :color, :atom, values: [:alert, :info, :warning, :gray], required: true

  def gamification_item(assigns) do
    ~H"""
    <span
      class={[
        "flex items-center gap-1 font-semibold text-sm",
        @color == :alert and "text-alert",
        @color == :info and "text-info",
        @color == :warning and "text-warning",
        @color == :gray and "text-gray"
      ]}
      id={@id}
    >
      <.icon name={@icon} title={@title} /> <%= @count %>
    </span>
    """
  end
end
