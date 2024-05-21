defmodule ZoonkWeb.Live.CourseList do
  @moduledoc false
  use ZoonkWeb, :live_view

  import ZoonkWeb.Components.Content.CourseList

  alias Zoonk.Content

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
