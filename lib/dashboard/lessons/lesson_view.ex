defmodule UneebeeWeb.Live.Dashboard.LessonView do
  @moduledoc false
  use UneebeeWeb, :live_view

  import UneebeeWeb.Components.Dashboard.StepImage

  alias Uneebee.Content
  alias UneebeeWeb.Components.Dashboard.LessonEdit
  alias UneebeeWeb.Components.Dashboard.LessonPublish
  alias UneebeeWeb.Components.Dashboard.OptionList
  alias UneebeeWeb.Components.Dashboard.StepContent
  alias UneebeeWeb.Components.Dashboard.StepSwitch
  alias UneebeeWeb.Components.Upload

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
    %{lesson: lesson, course: course} = socket.assigns

    step = Content.get_lesson_step_by_order(lesson, params["step_order"])
    lessons = Content.list_lessons(course.id)

    socket =
      socket
      |> assign(:selected_step, step)
      |> get_option(params["option_id"])
      |> assign(:lessons, lessons)

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

  @impl Phoenix.LiveView
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
end
