defmodule ZoonkWeb.Live.MissionList do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Gamification
  alias Zoonk.Gamification.MissionUtils

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{current_user: user} = socket.assigns

    user_missions = Gamification.completed_missions(user.id)
    completed_missions = get_completed_missions(user_missions)
    incomplete_missions = get_incomplete_missions(completed_missions)

    socket =
      socket
      |> assign(:page_title, dgettext("gamification", "Missions"))
      |> assign(:completed_missions, completed_missions)
      |> assign(:incomplete_missions, incomplete_missions)

    {:ok, socket}
  end

  defp get_completed_missions(user_missions) do
    Enum.map(user_missions, fn mission -> MissionUtils.mission(mission.reason) end)
  end

  defp get_incomplete_missions(completed_missions) do
    missions = MissionUtils.supported_missions()
    Enum.filter(missions, fn mission -> !Enum.member?(completed_missions, mission) end)
  end
end
