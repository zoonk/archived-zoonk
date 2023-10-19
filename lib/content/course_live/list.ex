defmodule UneebeeWeb.Live.Content.Course.List do
  @moduledoc false
  use UneebeeWeb, :live_view

  import UneebeeWeb.Components.Content.CourseList

  alias Uneebee.Content

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    %{current_user: user, school: school} = socket.assigns

    courses = Content.list_public_courses_by_school(school, session["locale"])
    courses_learning = list_courses_by_user(user, :student)

    socket =
      socket
      |> assign(:page_title, gettext("Courses"))
      |> stream(:courses, courses)
      |> stream(:courses_learning, courses_learning)
      |> assign(:courses_learning_empty?, courses_learning == [])

    {:ok, socket}
  end

  defp list_courses_by_user(nil, _role), do: []
  defp list_courses_by_user(user, role), do: Content.list_courses_by_user(user, role)
end
