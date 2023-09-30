defmodule UneebeeWeb.Live.Home do
  @moduledoc false
  use UneebeeWeb, :live_view

  import UneebeeWeb.Components.Content.CourseList

  alias Uneebee.Content

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{current_user: user, school: school} = socket.assigns

    courses_learning = list_courses_by_user(user, :student)
    courses = Content.list_public_courses_by_school(school, limit: 20)

    socket =
      socket
      |> assign(:page_title, gettext("Home"))
      |> stream(:courses_learning, courses_learning)
      |> stream(:courses, courses)
      |> assign(:courses_learning_empty?, courses_learning == [])

    {:ok, socket}
  end

  defp list_courses_by_user(nil, _role), do: []
  defp list_courses_by_user(user, role), do: Content.list_courses_by_user(user, role, limit: 3)
end
