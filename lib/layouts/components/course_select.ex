# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule UneebeeWeb.Components.Layouts.CourseSelect do
  @moduledoc false
  use UneebeeWeb, :live_component

  alias Uneebee.Content

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <form id="select-course" phx-change="select-course">
      <.input type="select" name="course" value={@selected} options={@courses} mt={false} />
    </form>
    """
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    %{school_id: school_id, user_id: user_id, role: role} = assigns
    courses = list_courses(school_id, user_id, role)

    socket = socket |> assign(assigns) |> assign(:courses, course_options(courses))

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("select-course", %{"course" => course_slug}, socket) do
    {:noreply, push_navigate(socket, to: course_link(course_slug))}
  end

  defp course_link("new-course"), do: ~p"/dashboard/courses/new"
  defp course_link(slug), do: ~p"/dashboard/c/#{slug}"

  defp list_courses(school_id, _user, :manager), do: Content.list_courses_by_school(school_id)
  defp list_courses(_school, user_id, :teacher), do: Content.list_courses_by_user(user_id, :teacher)

  defp course_options(courses) do
    [{gettext("Create a course"), "new-course"}] ++ Enum.map(courses, fn course -> {course.name, course.slug} end)
  end
end
