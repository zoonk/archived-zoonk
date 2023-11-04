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
    <.award_badge id="learning-days-badge" icon="tabler-calendar-heart" value={@days} label={dngettext("gamification", "Learning day", "Learning days", @days)} />
    """
  end

  @doc """
  Renders a badge for a medal.
  """
  attr :medal, Medal, required: true

  def medal_badge(assigns) do
    ~H"""
    <.award_badge id="medal-badge" color={medal_color(@medal.medal)} icon="tabler-medal" value={@medal.label} label={@medal.description} />
    """
  end

  defp medal_color(:gold), do: :warning
  defp medal_color(:silver), do: :gray
  defp medal_color(:bronze), do: :bronze
  defp medal_color(_prize), do: :primary

  @doc """
  Completed course trophy.
  """
  attr :trophy, Trophy, required: true

  def trophy_badge(assigns) do
    ~H"""
    <.award_badge id="trophy-badge" color={:warning} icon="tabler-trophy" value={@trophy.label} label={@trophy.description} />
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
      id={"mission-badge-#{@mission.key}"}
      color={medal_color(@mission.prize)}
      icon={if @mission.prize == :trophy, do: "tabler-trophy", else: "tabler-medal"}
      value={@mission.label}
      label={if @completed, do: @mission.success_message, else: @mission.description}
    />
    """
  end

  attr :id, :string, required: true
  attr :color, :atom, default: :primary, values: [:primary, :warning, :alert, :gray, :bronze]
  attr :icon, :string, required: true
  attr :value, :string, required: true
  attr :label, :string, required: true

  defp award_badge(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "flex flex-1 flex-col items-center gap-1 rounded-2xl p-4 text-center",
        @color == :primary && "bg-indigo-100 text-indigo-700",
        @color == :warning && "bgamber-200 textamber-900",
        @color == :alert && "bg-pink-200 text-pink-700",
        @color == :gray && "bg-gray-200 text-gray-900",
        @color == :bronze && "bg-orange-200 text-orange-900"
      ]}
    >
      <.icon name={@icon} />
      <span class="font-black"><%= @value %></span>
      <span class="text-xs font-light"><%= @label %></span>
    </div>
    """
  end
end
