defmodule ZoonkWeb.Live.Dashboard.CourseView do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Content
  alias ZoonkWeb.Components.Dashboard.CoursePublish

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{course: course} = socket.assigns

    lessons = Content.list_lessons_with_stats(course.id)

    socket =
      socket
      |> assign(:page_title, course.name)
      |> assign(:lessons, lessons)

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
      {:ok, _lesson} ->
        {:noreply, push_navigate(socket, to: ~p"/dashboard/c/#{course.slug}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not create lesson!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("reposition", %{"new" => new_index, "old" => old_index}, socket) when new_index != old_index do
    case Content.update_lesson_order(socket.assigns.course.id, old_index, new_index) do
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
end
