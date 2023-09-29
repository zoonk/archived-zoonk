defmodule UneebeeWeb.Live.Dashboard.CourseList do
  @moduledoc false
  use UneebeeWeb, :live_view

  import UneebeeWeb.Components.Dashboard.CourseList

  alias Uneebee.Content

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{current_user: user, school: school, user_role: role} = socket.assigns

    courses = list_courses(school, user, role)

    socket = socket |> assign(:page_title, gettext("Courses")) |> stream(:courses, courses)

    {:ok, socket}
  end

  defp list_courses(school, _user, :manager), do: Content.list_courses_by_school(school)
  defp list_courses(_school, user, :teacher), do: Content.list_courses_by_user(user, :teacher)
end
