defmodule UneebeeWeb.Components.Dashboard.LessonEdit do
  @moduledoc false
  use UneebeeWeb, :live_component

  alias Uneebee.Content

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="mt-16 flex items-center justify-between gap-2 rounded-2xl">
      <div></div>

      <.button
        icon="tabler-trash"
        phx-click="delete-lesson"
        color={:alert}
        phx-target={@myself}
        data-confirm={dgettext("orgs", "All content from this lesson will be deleted. This action cannot be undone.")}
      >
        <%= dgettext("orgs", "Delete lesson") %>
      </.button>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def handle_event("delete-lesson", _params, socket) do
    %{lesson: lesson, course: course} = socket.assigns

    case Content.delete_lesson(lesson) do
      {:ok, _lesson} ->
        first_lesson = Content.get_first_lesson(course)

        {:noreply, push_navigate(socket, to: lesson_link(course, first_lesson))}

      {:error, _changeset} ->
        {:noreply, put_flash!(socket, :error, dgettext("orgs", "Could not delete lesson!"))}
    end
  end

  defp lesson_link(course, nil), do: ~p"/dashboard/c/#{course.slug}"
  defp lesson_link(course, lesson), do: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1"
end
