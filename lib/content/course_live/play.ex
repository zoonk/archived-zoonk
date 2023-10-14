defmodule UneebeeWeb.Live.Content.Course.Play do
  @moduledoc false
  use UneebeeWeb, :live_view

  import UneebeeWeb.Components.Content.LessonProgress
  import UneebeeWeb.Components.Content.LessonStep

  alias Uneebee.Content
  alias Uneebee.Content.Lesson

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{lesson: %Lesson{} = lesson} = socket.assigns

    steps = Content.list_lesson_steps(lesson)

    socket =
      socket
      |> assign(:page_title, lesson.name)
      |> assign(:completed_steps, [])
      |> assign(:steps, steps)
      |> assign(:selected_options, [])

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("select-option", %{"selected_option" => selected_option}, socket) do
    %{current_user: user, lesson: lesson, completed_steps: completed, steps: steps, selected_options: selected_options} = socket.assigns

    option_id = String.to_integer(selected_option)
    attrs = %{user_id: user.id, option_id: option_id, lesson_id: lesson.id}

    case Content.add_user_selection(attrs) do
      {:ok, _} ->
        [current | remaining] = steps

        correct? = get_option(current.options, option_id).correct?

        socket =
          socket
          |> assign(:steps, remaining)
          |> assign(:completed_steps, completed ++ [current])
          |> assign(:selected_options, selected_options ++ [option_id])
          |> push_event("option-selected", %{isCorrect: correct?})

        {:noreply, handle_lesson_completed(socket, remaining)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, dgettext("courses", "Unable to select option"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("next-step", _params, socket) do
    %{completed_steps: completed, steps: steps, selected_options: selected_options} = socket.assigns

    [current | remaining] = steps

    socket =
      socket
      |> assign(:steps, remaining)
      |> assign(:completed_steps, completed ++ [current])
      |> assign(:selected_options, selected_options ++ [nil])

    {:noreply, handle_lesson_completed(socket, remaining)}
  end

  defp handle_lesson_completed(socket, []) do
    %{course: course, lesson: lesson, current_user: user} = socket.assigns

    case Content.mark_lesson_as_completed(user.id, lesson.id) do
      {:ok, _} ->
        redirect(socket, to: ~p"/c/#{course.slug}/#{lesson.id}/completed")

      {:error, _} ->
        {:noreply, put_flash(socket, :error, dgettext("courses", "Unable to complete lesson"))}
    end
  end

  defp handle_lesson_completed(socket, _completed), do: socket

  defp get_option(options, option_id), do: Enum.find(options, &(&1.id == option_id))
end
