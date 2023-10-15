defmodule UneebeeWeb.Live.Dashboard.LessonView do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Content
  alias Uneebee.Content.LessonStep
  alias Uneebee.Content.StepOption
  alias UneebeeWeb.Components.Dashboard.LessonPublish
  alias UneebeeWeb.Components.Dashboard.LessonSwitch
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
    %{lesson: lesson, live_action: live_action} = socket.assigns

    step = Content.get_lesson_step_by_order(lesson, params["step_order"])

    socket =
      socket
      |> assign(:selected_step, step)
      |> get_option(params)
      |> get_step_form(step, live_action)

    {:noreply, socket}
  end

  defp get_option(socket, %{"option_id" => option_id}) do
    option = Content.get_step_option!(option_id)
    changeset = Content.change_step_option(option)
    socket |> assign(:selected_option, option) |> assign(:option_form, to_form(changeset))
  end

  defp get_option(socket, _params), do: socket

  defp get_step_form(socket, step, :edit), do: assign(socket, :step_form, to_form(Content.change_lesson_step(step)))
  defp get_step_form(socket, _step, _action), do: socket

  @impl Phoenix.LiveView
  def handle_event("validate-step", %{"lesson_step" => lesson_step_params}, socket) do
    changeset = %LessonStep{} |> Content.change_lesson_step(lesson_step_params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, step_form: to_form(changeset))}
  end

  @impl Phoenix.LiveView
  def handle_event("validate-option", %{"step_option" => step_option_params}, socket) do
    changeset = %StepOption{} |> Content.change_step_option(step_option_params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, option_form: to_form(changeset))}
  end

  @impl Phoenix.LiveView
  def handle_event("reposition", %{"new" => new_index, "old" => old_index}, socket) when new_index != old_index do
    %{course: course, lesson: lesson, selected_step: step} = socket.assigns

    case Content.update_lesson_step_order(socket.assigns.lesson, old_index, new_index) do
      {:ok, _steps} ->
        {:noreply, push_patch(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{step.order}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not change the step order!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("reposition", %{"new" => new_index, "old" => old_index}, socket) when new_index == old_index do
    {:noreply, socket}
  end

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
  def handle_event("update-step", %{"lesson_step" => lesson_step_params}, socket) do
    %{course: course, lesson: lesson, selected_step: selected_step} = socket.assigns

    case Content.update_lesson_step(selected_step, lesson_step_params) do
      {:ok, _lesson_step} ->
        {:noreply, push_patch(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{selected_step.order}")}

      {:error, changeset} ->
        socket =
          socket
          |> put_flash(:error, dgettext("orgs", "Could not update step!"))
          |> assign(step_form: to_form(changeset))

        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("delete-option", params, socket) do
    %{course: course, lesson: lesson, selected_step: step} = socket.assigns
    option_id = String.to_integer(params["option-id"])

    case Content.delete_step_option(option_id) do
      {:ok, _option} ->
        {:noreply, push_patch(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{step.order}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not delete option!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("add-option", %{"step-id" => step_id}, socket) do
    %{course: course, lesson: lesson, selected_step: step} = socket.assigns

    attrs = %{lesson_step_id: String.to_integer(step_id), title: dgettext("orgs", "Untitled option")}

    case Content.create_step_option(attrs) do
      {:ok, _option} ->
        {:noreply, push_patch(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{step.order}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not add option!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("update-option", %{"step_option" => option_params}, socket) do
    %{course: course, lesson: lesson, selected_option: option, selected_step: step} = socket.assigns

    case Content.update_step_option(option, option_params) do
      {:ok, _option} ->
        {:noreply, push_patch(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{step.order}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not update option!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({Upload, :step_img, new_path}, socket) do
    %{course: course, lesson: lesson, selected_step: selected_step} = socket.assigns

    case Content.update_lesson_step(selected_step, %{image: new_path}) do
      {:ok, _lesson_step} ->
        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "Image updated!"))
          |> push_patch(to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{selected_step.order}")

        {:noreply, socket}

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
  def handle_info({LessonSwitch, :lesson_switch, step_count}, socket) do
    %{course: course, lesson: lesson} = socket.assigns
    {:noreply, socket |> assign(step_count: step_count) |> push_patch(to: step_link(course, lesson, step_count))}
  end

  defp step_link(course, lesson, order), do: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{order}"
  defp step_edit(course, lesson, order), do: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{order}/edit"
  defp step_img_link(course, lesson, order), do: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{order}/image"
  defp option_link(course, lesson, order, option), do: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{order}/o/#{option.id}"
  defp option_img_link(course, lesson, order, option), do: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{order}/o/#{option.id}/image"
end
