# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.AwardBadge do
  @moduledoc """
  Award badges.

  Badges displayed when a user earns a medal or an award.
  """
  use Phoenix.Component

  import UneebeeWeb.Components.Icon
  import UneebeeWeb.Gettext

  alias Uneebee.Gamification.Medal
  alias Uneebee.Gamification.Mission
  alias Uneebee.Gamification.Trophy

  @doc """
  Renders a badge for learning days.

  ## Examples

      <.learning_days_badge days={@learning_days} />
  """
  attr :days, :integer, required: true

  def learning_days_badge(assigns) do
    ~H"""
    <.award_badge id="learning-days-badge" icon="tabler-calendar-heart" prize={:other} value={@days} label={dngettext("gamification", "Learning day", "Learning days", @days)} />
    """
  end

  @doc """
  Renders a badge for a medal.
  """
  attr :medal, Medal, required: true

  def medal_badge(assigns) do
    ~H"""
    <.award_badge id="medal-badge" prize={@medal.medal} icon="tabler-medal" value={@medal.label} label={@medal.description} />
    """
  end

  @doc """
  Completed course trophy.
  """
  attr :trophy, Trophy, required: true

  def trophy_badge(assigns) do
    ~H"""
    <.award_badge id="trophy-badge" prize={:trophy} icon="tabler-trophy" value={@trophy.label} label={@trophy.description} />
    """
  end

  @doc """
  Badge for a completed mission.
  """
  attr :mission, Mission, required: true
  attr :completed, :boolean, default: false

  def mission_badge(assigns) do
    ~H"""
    <.award_badge
      id={"mission-#{@mission.label}"}
      prize={@mission.prize}
      icon={if @mission.prize == :trophy, do: "tabler-trophy", else: "tabler-medal"}
      value={@mission.label}
      label={if @completed, do: @mission.success_message, else: @mission.description}
    />
    """
  end

  attr :id, :string, required: true
  attr :prize, :atom, default: :other, values: [:gold, :silver, :bronze, :trophy, :other]
  attr :icon, :string, required: true
  attr :value, :string, required: true
  attr :label, :string, required: true

  defp award_badge(assigns) do
    ~H"""
    <dl id={@id} class={["overflow-hidden rounded-xl border ", prize_color_border(@prize), prize_color_text(@prize)]}>
      <div class={["flex items-center gap-x-2 border-b p-4", prize_color_border(@prize), prize_color_bg(@prize)]}>
        <.icon name={@icon} />
        <dt class="text-sm font-medium leading-6"><%= @value %></dt>
      </div>

      <div class="-my-3 px-4 py-2 text-sm leading-6">
        <dd class="py-3"><%= @label %></dd>
      </div>
    </dl>
    """
  end

  defp prize_color_bg(:gold), do: "bg-yellow-50"
  defp prize_color_bg(:silver), do: "bg-gray-50"
  defp prize_color_bg(:bronze), do: "bg-orange-50"
  defp prize_color_bg(_prize), do: "bg-teal-50"

  defp prize_color_text(:gold), do: "text-yellow-900"
  defp prize_color_text(:silver), do: "text-gray-900"
  defp prize_color_text(:bronze), do: "text-orange-900"
  defp prize_color_text(_prize), do: "text-teal-900"

  defp prize_color_border(:gold), do: "border-yellow-100"
  defp prize_color_border(:silver), do: "border-gray-100"
  defp prize_color_border(:bronze), do: "border-orange-100"
  defp prize_color_border(_prize), do: "border-teal-100"
end
