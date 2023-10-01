defmodule UneebeeWeb.Live.Home do
  @moduledoc false
  use UneebeeWeb, :live_view

  import UneebeeWeb.Components.Content.CourseList
  import UneebeeWeb.Components.Home.GamificationItem

  alias Uneebee.Content
  alias Uneebee.Gamification

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{current_user: user, school: school} = socket.assigns

    courses_learning = list_courses_by_user(user, :student)
    courses = Content.list_public_courses_by_school(school, limit: 20)
    learning_days = get_learning_days(user)
    medals = get_user_medals(user)

    socket =
      socket
      |> assign(:page_title, gettext("Home"))
      |> stream(:courses_learning, courses_learning)
      |> stream(:courses, courses)
      |> assign(:courses_learning_empty?, courses_learning == [])
      |> assign(:learning_days, learning_days)
      |> assign(:medals, medals)

    {:ok, socket}
  end

  defp list_courses_by_user(nil, _role), do: []
  defp list_courses_by_user(user, role), do: Content.list_courses_by_user(user, role, limit: 3)

  defp get_learning_days(nil), do: nil
  defp get_learning_days(user), do: Gamification.learning_days_count(user.id)

  defp get_user_medals(nil), do: nil
  defp get_user_medals(user), do: Gamification.count_user_medals(user.id)
end
