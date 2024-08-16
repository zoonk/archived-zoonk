defmodule ZoonkWeb.Live.Dashboard.LessonEditor do
  @moduledoc false
  use ZoonkWeb, :live_view

  import ZoonkWeb.Components.Dashboard.SegmentEdit
  import ZoonkWeb.Components.Dashboard.StepImage

  alias Zoonk.Content
  alias Zoonk.Storage
  alias ZoonkWeb.Components.Dashboard.LessonEdit
  alias ZoonkWeb.Components.Dashboard.LessonPublish
  alias ZoonkWeb.Components.Dashboard.OptionList
  alias ZoonkWeb.Components.Dashboard.StepContent
  alias ZoonkWeb.Components.Dashboard.StepFill
  alias ZoonkWeb.Components.Dashboard.StepSwitch
  alias ZoonkWeb.Components.Upload

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{lesson: lesson} = socket.assigns

    step_count = Content.count_lesson_steps(lesson.id)

    socket =
      socket
      |> assign(:page_title, lesson.name)
      |> assign(:step_count, step_count)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    %{lesson: lesson, course: course, school: school} = socket.assigns

    step = Content.get_lesson_step_by_order(lesson.id, params["step_order"])
    lessons = Content.list_lessons(course.id)
    suggested_courses = Content.list_step_suggested_courses(step.id)
    updated_lesson = Enum.find(lessons, fn l -> l.id == lesson.id end)

    socket =
      socket
      |> assign(:selected_step, step)
      |> get_option(params["option_id"])
      |> assign(:lessons, lessons)
      |> assign(:suggested_courses, suggested_courses)
      |> assign(:search_results, search_courses(school.id, params["term"]))
      |> assign(:lesson, updated_lesson)
      |> assign(:segment, get_segment_by_index(step.segments, params["segment_idx"]))
      |> assign(:segment_idx, params["segment_idx"])

    {:noreply, socket}
  end

  defp get_option(socket, nil), do: assign(socket, :selected_option, nil)
  defp get_option(socket, option_id), do: assign(socket, :selected_option, Content.get_step_option!(option_id))

  @impl Phoenix.LiveView
  def handle_event("delete-step", params, socket) do
    %{course: course, lesson: lesson, step_count: step_count} = socket.assigns
    step_id = String.to_integer(params["step-id"])

    case Content.delete_lesson_step(step_id) do
      {:ok, _lesson_step} ->
        socket =
          socket
          |> assign(:step_count, step_count - 1)
          |> push_patch(to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not delete step!"))}
    end
  end

  def handle_event("search", %{"term" => search_term}, socket) do
    %{course: course, lesson: lesson, selected_step: step} = socket.assigns
    {:noreply, push_patch(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{step.order}/search?term=#{search_term}")}
  end

  def handle_event("add-option", %{"step-id" => step_id}, socket) do
    %{course: course, lesson: lesson, selected_step: step} = socket.assigns

    attrs = %{lesson_step_id: String.to_integer(step_id), title: dgettext("orgs", "Untitled option")}

    case Content.create_step_option(attrs) do
      {:ok, option} ->
        {:noreply, push_patch(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{step.order}/o/#{option.id}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not add option!"))}
    end
  end

  def handle_event("update-step-kind", %{"kind" => kind}, socket) do
    %{selected_step: step, course: course, lesson: lesson} = socket.assigns

    case Content.update_lesson_step_kind(step, kind) do
      {:ok, _lesson_step} ->
        {:noreply, push_patch(socket, to: step_link(course, lesson, step.order))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not update step kind!"))}
    end
  end

  def handle_event("delete-lesson", _params, socket) do
    %{lesson: lesson, course: course} = socket.assigns

    case Content.delete_lesson(lesson) do
      {:ok, _lesson} ->
        first_lesson = Content.get_first_lesson(course)

        {:noreply, push_navigate(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{first_lesson.id}/s/1")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not delete lesson!"))}
    end
  end

  def handle_event("delete-suggested-course", %{"suggested-course-id" => suggested_course_id}, socket) do
    %{course: course, lesson: lesson, selected_step: step} = socket.assigns

    case Content.delete_step_suggested_course(suggested_course_id) do
      {:ok, _suggested_course} ->
        {:noreply, push_patch(socket, to: step_link(course, lesson, step.order))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not delete suggested course!"))}
    end
  end

  def handle_event("update-segment", %{"segment" => segment}, socket) do
    %{course: course, lesson: lesson, selected_step: step, segment_idx: segment_idx} = socket.assigns

    case Content.update_step_segment(step, String.to_integer(segment_idx), segment) do
      {:ok, _lesson_step} ->
        {:noreply, push_patch(socket, to: step_link(course, lesson, step.order))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not update segment!"))}
    end
  end

  def handle_event("delete-segment", _params, socket) do
    %{course: course, lesson: lesson, selected_step: step, segment_idx: segment_idx} = socket.assigns

    case Content.delete_step_segment(step, String.to_integer(segment_idx)) do
      {:ok, _lesson_step} ->
        {:noreply, push_patch(socket, to: step_link(course, lesson, step.order))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not delete segment!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({Upload, :step_img_upload, new_path}, socket) do
    %{course: course, lesson: lesson, selected_step: selected_step} = socket.assigns

    case Content.update_lesson_step(selected_step, %{image: new_path}) do
      {:ok, _lesson_step} ->
        {:noreply, push_patch(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{selected_step.order}")}

      {:error, _changeset} ->
        socket = put_flash(socket, :error, dgettext("orgs", "Could not update image!"))

        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({Upload, :option_img, new_path}, socket) do
    %{course: course, lesson: lesson, selected_option: option, selected_step: step} = socket.assigns

    case Content.update_step_option(option, %{image: new_path}) do
      {:ok, _option} ->
        {:noreply, push_patch(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{step.order}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not update option!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({StepSwitch, :step_switch, step_count}, socket) do
    %{course: course, lesson: lesson} = socket.assigns
    {:noreply, socket |> assign(step_count: step_count) |> push_patch(to: step_link(course, lesson, step_count))}
  end

  @impl Phoenix.LiveView
  def handle_info({Upload, :lesson_cover, new_path}, socket) do
    %{lesson: lesson, course: course, selected_step: step} = socket.assigns

    case Content.update_lesson(lesson, %{cover: new_path}) do
      {:ok, _updated_lesson} ->
        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "Cover updated successfully!"))
          |> push_patch(to: step_link(course, lesson, step.order))

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not update cover!"))}
    end
  end

  defp step_link(course, lesson, order), do: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{order}"
  defp segment_link(course, lesson, order, segment_idx), do: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{order}/segment/#{segment_idx}"

  defp search_courses(_school_id, nil), do: []
  defp search_courses(school_id, term), do: Content.search_courses_by_school(school_id, term)

  defp answer_types do
    [
      %{
        kind: :readonly,
        icon: "tabler-dialpad-off",
        title: dgettext("orgs", "Read-only"),
        description: dgettext("orgs", "Users can only read the content. No options are displayed.")
      },
      %{
        kind: :quiz,
        icon: "tabler-dialpad",
        title: dgettext("orgs", "Quiz"),
        description: dgettext("orgs", "You can add multiple options and users can select one of them.")
      },
      %{
        kind: :open_ended,
        icon: "tabler-writing",
        title: dgettext("orgs", "Open-ended"),
        description: dgettext("orgs", "Users can write their own answer.")
      },
      %{
        kind: :fill,
        icon: "tabler-forms",
        title: dgettext("orgs", "Fill in the blank"),
        description: dgettext("orgs", "Users can fill in the blank space in a sentence.")
      }
    ]
  end

  # Returns only options associated with a step segment
  defp options_with_segments(options) do
    options
    |> Enum.filter(fn option -> option.segment end)
    |> Enum.map(fn %{title: title, segment: segment} -> %{title: title, segment: segment} end)
  end

  def get_segment_by_index(_segments, nil), do: nil
  def get_segment_by_index(segments, index), do: Enum.at(segments, String.to_integer(index))
end
