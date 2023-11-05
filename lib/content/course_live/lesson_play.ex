defmodule UneebeeWeb.Live.LessonPlay do
  @moduledoc false
  use UneebeeWeb, :live_view

  import UneebeeWeb.Components.Content.LessonStep

  alias Uneebee.Content
  alias Uneebee.Content.Lesson
  alias Uneebee.Content.LessonStep
  alias Uneebee.Content.StepOption

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{lesson: %Lesson{} = lesson} = socket.assigns

    step_count = Content.count_lesson_steps(lesson.id)
    current_step = Content.get_next_step(lesson, 0)

    socket =
      socket
      |> assign(:page_title, lesson.name)
      |> assign(:step_count, step_count)
      |> assign(:current_step, current_step)
      |> assign(:selected_option, nil)
      |> assign(:options, shuffle_options(current_step))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("next", %{"selected_option" => selected_option}, socket) when is_nil(socket.assigns.selected_option) do
    %{current_user: user, lesson: lesson, current_step: step} = socket.assigns

    option_id = String.to_integer(selected_option)
    attrs = %{user_id: user.id, option_id: option_id, lesson_id: lesson.id}

    case Content.add_user_selection(attrs) do
      {:ok, _} ->
        selected_option = get_option(step.options, option_id)

        socket =
          socket
          |> push_event("option-selected", %{isCorrect: selected_option.correct?})
          |> assign(:selected_option, selected_option)

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, dgettext("courses", "Unable to select option"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("next", _params, socket) do
    %{lesson: lesson, current_step: current_step} = socket.assigns
    next_step = Content.get_next_step(lesson, current_step.order)

    socket =
      socket
      |> assign(:selected_option, nil)
      |> assign(:current_step, next_step)
      |> assign(:options, shuffle_options(next_step))
      |> handle_lesson_completed(next_step)

    {:noreply, socket}
  end

  defp handle_lesson_completed(socket, nil) do
    %{course: course, lesson: lesson, current_user: user} = socket.assigns

    case Content.mark_lesson_as_completed(user.id, lesson.id) do
      {:ok, _} ->
        redirect(socket, to: ~p"/c/#{course.slug}/#{lesson.id}/completed")

      {:error, _} ->
        {:noreply, put_flash(socket, :error, dgettext("courses", "Unable to complete lesson"))}
    end
  end

  defp handle_lesson_completed(socket, _next_step), do: socket

  defp get_option(options, option_id), do: Enum.find(options, &(&1.id == option_id))

  defp user_selected_wrong_option?(%StepOption{correct?: false} = selected, option) when selected.id == option.id, do: true
  defp user_selected_wrong_option?(_selected, _option), do: false

  defp shuffle_options(nil), do: nil
  defp shuffle_options(%LessonStep{} = step), do: Enum.shuffle(step.options)

  defp confirm_color([], _selected), do: :primary
  defp confirm_color(_opts, %StepOption{correct?: true}), do: :success
  defp confirm_color(_opts, %StepOption{correct?: false}), do: :alert
  defp confirm_color(_opts, nil), do: :alert
end
