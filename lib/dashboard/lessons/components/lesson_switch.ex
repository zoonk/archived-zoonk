defmodule UneebeeWeb.Components.Dashboard.LessonSwitch do
  @moduledoc false
  use UneebeeWeb, :live_component

  alias Uneebee.Content

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <form id="select-lesson" phx-change="select-lesson" phx-target={@myself}>
      <.input type="select" name="lesson" value={@active} options={lesson_options(@lessons)} />
    </form>
    """
  end

  defp lesson_options(lessons) do
    [{dgettext("orgs", "Create a lesson"), "new-lesson"}] ++ Enum.map(lessons, fn lesson -> {lesson.name, lesson.id} end)
  end

  @impl Phoenix.LiveComponent
  def handle_event("select-lesson", %{"lesson" => "new-lesson"}, socket) do
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

        {:noreply, push_navigate(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not create lesson!"))}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("select-lesson", %{"lesson" => lesson_id}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/dashboard/c/#{socket.assigns.course.slug}/l/#{lesson_id}/s/1")}
  end
end
