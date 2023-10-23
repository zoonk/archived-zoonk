defmodule UneebeeWeb.Live.MyCourses do
  @moduledoc false
  use UneebeeWeb, :live_view

  import UneebeeWeb.Components.Content.CourseList

  alias Uneebee.Content

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{current_user: user} = socket.assigns

    courses = Content.list_courses_by_user(user, :student)

    socket =
      socket
      |> assign(:page_title, gettext("My courses"))
      |> stream(:courses, courses)
      |> assign(:courses_empty?, Enum.empty?(courses))

    {:ok, socket}
  end
end
