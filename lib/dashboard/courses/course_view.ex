defmodule UneebeeWeb.Live.Dashboard.CourseView do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Content
  alias UneebeeWeb.Components.Dashboard.CoursePublish

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{course: course, school: school, user_role: role, current_user: user} = socket.assigns

    lessons = Content.list_lessons(course)
    courses = list_courses(school, user, role)

    socket =
      socket
      |> assign(:page_title, course.name)
      |> assign(:lessons, lessons)
      |> assign(:courses, course_options(courses))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("add-lesson", _params, socket) do
    %{course: course, lessons: lessons} = socket.assigns

    order = length(lessons) + 1

    attrs = %{
      course_id: course.id,
      order: order,
      name: dgettext("orgs", "Lesson %{order}", order: order),
      description: dgettext("orgs", "Description for lesson %{order}. You should update this.", order: order)
    }

    case Content.create_lesson(attrs) do
      {:ok, lesson} ->
        Content.create_lesson_step(%{lesson_id: lesson.id, order: 1, content: dgettext("orgs", "Untitled step")})

        {:noreply, push_navigate(socket, to: ~p"/dashboard/c/#{course.slug}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not create lesson!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("select-course", %{"course" => course_slug}, socket) do
    {:noreply, push_navigate(socket, to: course_link(course_slug))}
  end

  @impl Phoenix.LiveView
  def handle_event("reposition", %{"new" => new_index, "old" => old_index}, socket) when new_index != old_index do
    case Content.update_lesson_order(socket.assigns.course, old_index, new_index) do
      {:ok, lessons} ->
        {:noreply, assign(socket, :lessons, lessons)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not change the lesson order!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("reposition", %{"new" => new_index, "old" => old_index}, socket) when new_index == old_index do
    {:noreply, socket}
  end

  defp course_options(courses) do
    [{gettext("Create a course"), "new-course"}] ++ Enum.map(courses, fn course -> {course.name, course.slug} end)
  end

  defp list_courses(school, _user, :manager), do: Content.list_courses_by_school(school)
  defp list_courses(_school, user, :teacher), do: Content.list_courses_by_user(user, :teacher)

  defp course_link("new-course"), do: ~p"/dashboard/courses/new"
  defp course_link(slug), do: ~p"/dashboard/c/#{slug}"
end
