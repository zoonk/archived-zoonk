defmodule UneebeeWeb.Live.Home do
  @moduledoc false
  use UneebeeWeb, :live_view

  import UneebeeWeb.Components.Content.CourseList
  import UneebeeWeb.Components.Home.GamificationItem

  alias Uneebee.Content
  alias Uneebee.Gamification
  alias Uneebee.Gamification.MissionUtils

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    %{current_user: user, school: school} = socket.assigns

    courses_learning = list_courses_by_user(user, :student)
    courses = Content.list_public_courses_by_school(school, session["locale"], limit: 20)
    learning_days = get_learning_days(user)
    medals = get_user_medals(user)
    trophies = get_user_trophies(user)
    mission_progress = mission_progress(user)

    socket =
      socket
      |> assign(:page_title, gettext("Home"))
      |> stream(:courses_learning, courses_learning)
      |> stream(:courses, courses)
      |> assign(:courses_learning_empty?, courses_learning == [])
      |> assign(:learning_days, learning_days)
      |> assign(:medals, medals)
      |> assign(:trophies, trophies)
      |> assign(:mission_progress, mission_progress)

    {:ok, socket}
  end

  defp list_courses_by_user(nil, _role), do: []
  defp list_courses_by_user(user, role), do: Content.list_courses_by_user(user, role, limit: 3)

  defp get_learning_days(nil), do: nil
  defp get_learning_days(user), do: Gamification.learning_days_count(user.id)

  defp get_user_medals(nil), do: nil
  defp get_user_medals(user), do: Gamification.count_user_medals(user.id)

  defp get_user_trophies(nil), do: nil
  defp get_user_trophies(user), do: Gamification.count_user_trophies(user.id)

  defp get_user_missions(user), do: Gamification.count_completed_missions(user.id)

  defp mission_progress(nil), do: 0
  defp mission_progress(user), do: user |> get_user_missions() |> Kernel./(supported_missions_count()) |> Kernel.*(100) |> round()

  defp supported_missions_count, do: length(MissionUtils.supported_missions())
end
