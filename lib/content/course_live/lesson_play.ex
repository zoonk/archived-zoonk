defmodule ZoonkWeb.Live.LessonPlay do
  @moduledoc false
  use ZoonkWeb, :live_view

  import Zoonk.Shared.Utilities, only: [boolean_to_integer: 1]
  import ZoonkWeb.Components.Content.FillOptions
  import ZoonkWeb.Components.Content.FillStep
  import ZoonkWeb.Components.Content.LessonStep

  alias Zoonk.Accounts.User
  alias Zoonk.Content
  alias Zoonk.Content.Lesson
  alias Zoonk.Content.LessonStep
  alias Zoonk.Content.StepOption
  alias Zoonk.Storage

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
      |> assign(:lesson_start, DateTime.utc_now())
      |> assign(:step_start, DateTime.utc_now())
      |> assign(:selected_segments, List.duplicate(nil, segment_count(current_step)))
      |> assign(:answer, [])

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("select-fill-option", %{"option-id" => option_id}, socket) do
    %{current_step: step, selected_segments: selected_segments} = socket.assigns
    option = get_option(step.options, String.to_integer(option_id))
    segment_index = next_segment_index(step.segments, selected_segments)

    socket =
      assign(socket, :selected_segments, List.replace_at(selected_segments, segment_index, option))

    {:noreply, socket}
  end

  def handle_event("remove-segment", %{"index" => index}, socket) do
    %{selected_segments: selected_segments} = socket.assigns
    segment_index = String.to_integer(index)

    socket =
      assign(socket, :selected_segments, List.replace_at(selected_segments, segment_index, nil))

    {:noreply, socket}
  end

  # confirm a selection for a fill in the blank step
  def handle_event("next", _params, socket) when socket.assigns.current_step.kind == :fill and socket.assigns.answer == [] do
    %{current_step: step, selected_segments: selected_segments} = socket.assigns
    correct_option_titles = list_correct_option_titles(step.segments, step.options)
    answer = list_segment_titles(selected_segments)
    correct? = correct_option_titles == answer

    socket =
      socket
      |> maybe_play_sound_effect(correct?)
      |> assign(:answer, answer)

    {:noreply, socket}
  end

  def handle_event("next", %{"selected_option" => selected_option}, socket) when is_nil(socket.assigns.selected_option) do
    %{current_step: step} = socket.assigns

    option_id = String.to_integer(selected_option)
    selected_option = get_option(step.options, option_id)

    socket =
      socket
      |> maybe_play_sound_effect(selected_option.correct?)
      |> assign(:selected_option, selected_option)

    {:noreply, socket}
  end

  def handle_event("next", params, socket) do
    %{current_user: user, lesson: lesson, current_step: current_step, step_start: step_start, selected_segments: selected_segments, selected_option: selected_option} =
      socket.assigns

    step_duration = DateTime.diff(DateTime.utc_now(), step_start, :second)
    next_step = Content.get_next_step(lesson, current_step.order)

    attrs = %{
      user_id: user.id,
      correct: get_correct_value(current_step, selected_option, selected_segments),
      total: get_total_value(current_step),
      lesson_id: lesson.id,
      step_id: current_step.id,
      option_id: get_selected_option_id(selected_option),
      answer: get_answer(params, socket.assigns),
      duration: step_duration
    }

    case Content.add_user_selection(attrs) do
      {:ok, _} ->
        socket =
          socket
          |> assign(:selected_option, nil)
          |> assign(:current_step, next_step)
          |> assign(:options, shuffle_options(next_step))
          |> assign(:answer, [])
          |> assign(:selected_segments, List.duplicate(nil, segment_count(next_step)))
          |> handle_lesson_completed(next_step)

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, dgettext("courses", "Unable to send answer"))}
    end
  end

  defp handle_lesson_completed(socket, nil) do
    %{course: course, lesson: lesson, current_user: user, lesson_start: lesson_start} = socket.assigns

    lesson_duration = DateTime.diff(DateTime.utc_now(), lesson_start, :second)

    case Content.mark_lesson_as_completed(user.id, lesson.id, lesson_duration) do
      {:ok, _} ->
        push_navigate(socket, to: ~p"/c/#{course.slug}/#{lesson.id}/completed")

      {:error, _} ->
        {:noreply, put_flash(socket, :error, dgettext("courses", "Unable to complete lesson"))}
    end
  end

  defp handle_lesson_completed(socket, _next_step), do: assign(socket, :step_start, DateTime.utc_now())

  defp get_option(options, option_id), do: Enum.find(options, &(&1.id == option_id))

  defp get_selected_option_id(nil), do: nil
  defp get_selected_option_id(selected_option), do: selected_option.id

  defp get_total_value(%LessonStep{kind: :fill, segments: segments}), do: empty_segment_count(segments)
  defp get_total_value(_), do: 1

  defp get_correct_value(%LessonStep{kind: :fill, segments: segments, options: options}, _option, selected_segments) do
    correct_option_titles = list_correct_option_titles(segments, options)
    answer = list_segment_titles(selected_segments)
    count_matching_items(correct_option_titles, answer)
  end

  defp get_correct_value(_step, nil, _segments), do: 1
  defp get_correct_value(_step, selected_option, _segments), do: boolean_to_integer(selected_option.correct?)

  defp user_selected_wrong_option?(%StepOption{correct?: false} = selected, option) when selected.id == option.id, do: true
  defp user_selected_wrong_option?(_selected, _option), do: false

  defp shuffle_options(nil), do: nil
  defp shuffle_options(%LessonStep{} = step), do: Enum.shuffle(step.options)

  defp confirm_color([], _selected), do: :primary
  defp confirm_color(_opts, %StepOption{correct?: true}), do: :success
  defp confirm_color(_opts, %StepOption{correct?: false}), do: :alert
  defp confirm_color(_opts, nil), do: :alert

  defp maybe_play_sound_effect(%{assigns: %User{sound_effects?: false}} = socket, _correct?), do: socket
  defp maybe_play_sound_effect(socket, correct?), do: push_event(socket, "option-selected", %{isCorrect: correct?})

  defp segment_count(nil), do: 0
  defp segment_count(%LessonStep{segments: nil}), do: 0
  defp segment_count(%LessonStep{segments: segments}), do: length(segments)

  defp empty_segment_count(nil), do: 0
  defp empty_segment_count(%LessonStep{segments: nil}), do: 0
  defp empty_segment_count(%LessonStep{segments: segments}), do: Enum.count(segments, &is_nil/1)

  # Find the index from a segment not selected by the user
  # We know a segment can be selected if it's nil.
  # For example: ["this", nil, "a", nil]
  # Users can select segments at index 1 and 3.
  # If they haven't selected an option, then we can get the first nil segment.
  # However, if they have selected an option, then we need to get the next nil segment.
  # This is why we need to check if the same index at selected_segments is also nil.
  defp next_segment_index(segments, selected_segments) do
    segments
    |> Enum.with_index()
    |> Enum.find(fn {segment, index} ->
      is_nil(segment) && is_nil(Enum.at(selected_segments, index))
    end)
    |> case do
      {_, index} -> index
      nil -> Enum.find_index(segments, &is_nil/1)
    end
  end

  # filters out the segments that are not nil and returns the titles
  defp list_segment_titles(segments) do
    segments
    |> Enum.filter(&(!is_nil(&1)))
    |> Enum.map(& &1.title)
  end

  # get the titles from correct options based on the segment index
  defp list_correct_option_titles(segments, options) do
    segments
    |> Enum.with_index()
    |> Enum.filter(fn {segment, _index} -> is_nil(segment) end)
    |> Enum.map(fn {_segment, index} ->
      options
      |> Enum.find(&(&1.segment == index))
      |> Map.get(:title)
    end)
  end

  # given two lists count how many items are in the same position
  defp count_matching_items(list1, list2) do
    list1 |> Enum.with_index() |> Enum.count(fn {item, index} -> item == Enum.at(list2, index) end)
  end

  defp get_answer(%{"answer" => answer}, _assigns), do: [answer]
  defp get_answer(_params, %{answer: answer}), do: answer
end
