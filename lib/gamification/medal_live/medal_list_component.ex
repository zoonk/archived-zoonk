# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule UneebeeWeb.Components.MedalList do
  @moduledoc false
  use UneebeeWeb, :html

  alias Uneebee.Gamification.MedalUtils

  attr :kind, :atom, values: [:gold, :silver, :bronze], required: true
  attr :medals, :list, required: true

  def medal_list(assigns) do
    ~H"""
    <section class="mb-8">
      <h2 class={["mb-2 font-bold", @kind == :gold && "text-amber-600", @kind == :silver && "text-gray-600", @kind == :bronze && "text-orange-600"]}>
        <%= list_title(@kind, total_medals(@medals)) %>
      </h2>

      <dl class="grid grid-cols-2 gap-4 sm:grid-cols-3">
        <.medal_badge
          :for={user_medal <- @medals}
          badge={medal_badge_label(user_medal.count)}
          prize={@kind}
          title={medal_title(user_medal)}
          description={medal_description(user_medal)}
        />
      </dl>
    </section>
    """
  end

  defp list_title(:gold, count), do: dngettext("gamification", "%{count} gold medal", "%{count} gold medals", count, count: count)
  defp list_title(:silver, count), do: dngettext("gamification", "%{count} silver medal", "%{count} silver medals", count, count: count)
  defp list_title(:bronze, count), do: dngettext("gamification", "%{count} bronze medal", "%{count} bronze medals", count, count: count)

  defp medal_badge_label(count), do: dngettext("gamification", "%{count} time", "%{count} times", count, count: count)

  defp total_medals(medals), do: Enum.reduce(medals, 0, fn medal, acc -> acc + medal.count end)
  defp medal(user_medal), do: MedalUtils.medal(user_medal.reason)
  defp medal_title(user_medal), do: medal(user_medal).label
  defp medal_description(user_medal), do: medal(user_medal).description
end
