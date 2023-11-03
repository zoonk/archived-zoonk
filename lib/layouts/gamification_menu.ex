# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Layouts.GamificationMenu do
  @moduledoc false
  use UneebeeWeb, :html

  attr :learning_days, :integer, required: true
  attr :mission_progress, :integer, required: true
  attr :trophies, :integer, required: true
  attr :medals, :integer, required: true

  def gamification_menu(assigns) do
    ~H"""
    <.gamification_item id="learning-days" color={:alert} icon="tabler-calendar-heart" title={dgettext("gamification", "Learning days")} count={@learning_days} />

    <.link navigate={~p"/missions"}>
      <.gamification_item id="missions" color={:info} icon="tabler-target-arrow" title={dgettext("gamification", "Missions")} count={"#{@mission_progress}%"} />
    </.link>

    <.link navigate={~p"/trophies"}>
      <.gamification_item id="trophies" color={:gray} icon="tabler-trophy" title={dgettext("gamification", "Trophies")} count={@trophies} />
    </.link>

    <.link navigate={~p"/medals"}>
      <.gamification_item id="medals" color={:warning} icon="tabler-medal" title={dgettext("gamification", "Medals")} count={@medals} />
    </.link>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :count, :string, required: true
  attr :icon, :string, required: true
  attr :color, :atom, values: [:alert, :info, :warning, :gray], required: true

  defp gamification_item(assigns) do
    ~H"""
    <span
      class={[
        "flex items-center gap-1 font-bold",
        @color == :alert and "text-alert",
        @color == :info and "text-info",
        @color == :warning and "text-warning",
        @color == :gray and "text-gray"
      ]}
      id={@id}
    >
      <.icon name={@icon} title={@title} class="h-5 w-5" /> <%= @count %>
    </span>
    """
  end
end
