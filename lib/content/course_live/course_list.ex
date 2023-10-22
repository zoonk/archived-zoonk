defmodule UneebeeWeb.Live.CourseList do
  @moduledoc false
  use UneebeeWeb, :live_view

  import UneebeeWeb.Components.Content.CourseList

  alias Uneebee.Content

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    %{school: school} = socket.assigns

    courses = Content.list_public_courses_by_school(school, session["locale"])

    socket =
      socket
      |> assign(:page_title, gettext("Courses"))
      |> stream(:courses, courses)

    {:ok, socket}
  end
end
