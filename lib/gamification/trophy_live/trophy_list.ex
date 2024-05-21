defmodule ZoonkWeb.Live.TrophyList do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Gamification
  alias Zoonk.Gamification.MissionUtils
  alias Zoonk.Gamification.TrophyUtils
  alias Zoonk.Gamification.UserTrophy

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{current_user: user} = socket.assigns

    user_trophies = Gamification.list_user_trophies(user.id)

    socket =
      socket
      |> assign(:page_title, dgettext("gamification", "Trophies"))
      |> assign(:user_trophies, user_trophies)

    {:ok, socket}
  end

  defp trophy_name(reason), do: TrophyUtils.trophy(reason).label

  defp description(%UserTrophy{reason: :course_completed, course: course}), do: course.name
  defp description(%UserTrophy{reason: :mission_completed, mission: mission}), do: MissionUtils.mission(mission.reason).success_message
end
