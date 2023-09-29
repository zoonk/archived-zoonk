defmodule UneebeeWeb.Live.Dashboard.CourseView do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Content

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{course: course} = socket.assigns

    lessons = Content.list_lessons(course)

    socket = socket |> assign(:page_title, course.name) |> assign(:lessons, lessons)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("add-lesson", _params, socket) do
    %{course: course, lessons: lessons} = socket.assigns

    order = length(lessons) + 1

    attrs = %{
      course_id: course.id,
      kind: :story,
      order: order,
      name: dgettext("courses", "Lesson %{order}", order: order),
      description: dgettext("courses", "Description for lesson %{order}. You should update this.", order: order)
    }

    case Content.create_lesson(attrs) do
      {:ok, _lesson} ->
        socket =
          socket
          |> put_flash(:info, dgettext("courses", "Lesson created!"))
          |> push_redirect(to: ~p"/dashboard/c/#{course.slug}")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("courses", "Could not create lesson!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("reposition", %{"new" => new_index, "old" => old_index}, socket) when new_index != old_index do
    case Content.update_lesson_order(socket.assigns.course, old_index, new_index) do
      {:ok, lessons} ->
        socket =
          socket
          |> put_flash(:info, dgettext("courses", "Lesson order changed!"))
          |> assign(:lessons, lessons)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("courses", "Could not change the lesson order!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("reposition", %{"new" => new_index, "old" => old_index}, socket) when new_index == old_index do
    {:noreply, socket}
  end
end
