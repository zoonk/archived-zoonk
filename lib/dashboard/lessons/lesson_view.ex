defmodule UneebeeWeb.Live.Dashboard.LessonView do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Content
  alias Uneebee.Content.LessonStep
  alias Uneebee.Content.StepOption
  alias UneebeeWeb.Components.Upload

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{lesson: lesson} = socket.assigns
    lesson_steps = Content.list_lesson_steps(lesson)
    step_changeset = Content.change_lesson_step(%LessonStep{})
    option_changeset = Content.change_step_option(%StepOption{})

    socket =
      socket
      |> assign(:page_title, lesson.name)
      |> assign(:lesson_steps, lesson_steps)
      |> assign(:step_form, to_form(step_changeset))
      |> assign(:option_form, to_form(option_changeset))
      |> assign(:selected_option, nil)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :view, _params), do: socket

  defp apply_action(socket, _action, %{"option_id" => option_id}) do
    option = Content.get_step_option!(option_id)
    changeset = Content.change_step_option(option)
    socket |> assign(:selected_option, option) |> assign(:option_form, to_form(changeset))
  end

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
  def handle_event("toggle-status", _params, socket) do
    %{lesson: lesson} = socket.assigns

    published? = !lesson.published?

    case Content.update_lesson(lesson, %{published?: published?}) do
      {:ok, updated_lesson} ->
        {:noreply, assign(socket, lesson: updated_lesson)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not update lesson!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("reposition", %{"new" => new_index, "old" => old_index}, socket) when new_index != old_index do
    case Content.update_lesson_step_order(socket.assigns.lesson, old_index, new_index) do
      {:ok, lesson_steps} ->
        {:noreply, assign(socket, lesson_steps: lesson_steps)}

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
    %{lesson_steps: lesson_steps} = socket.assigns
    step_id = String.to_integer(params["step-id"])

    case Content.delete_lesson_step(step_id) do
      {:ok, _lesson_step} ->
        updated_steps = Enum.reject(lesson_steps, fn step -> step.id == step_id end)

        {:noreply, assign(socket, lesson_steps: updated_steps)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not delete step!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("create-step", %{"lesson_step" => lesson_step_params}, socket) do
    %{lesson: lesson, lesson_steps: lesson_steps} = socket.assigns
    attrs = Map.put(lesson_step_params, "lesson_id", lesson.id)
    handle_create_step(socket, lesson_steps, attrs)
  end

  @impl Phoenix.LiveView
  def handle_event("delete-option", params, socket) do
    %{course: course, lesson: lesson} = socket.assigns
    option_id = String.to_integer(params["option-id"])

    case Content.delete_step_option(option_id) do
      {:ok, _option} ->
        {:noreply, push_navigate(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not delete option!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("add-option", %{"step-id" => step_id}, socket) do
    %{course: course, lesson: lesson} = socket.assigns

    attrs = %{lesson_step_id: String.to_integer(step_id), title: dgettext("orgs", "Untitled option")}

    case Content.create_step_option(attrs) do
      {:ok, _option} ->
        {:noreply, push_navigate(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not add option!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("update-option", %{"step_option" => option_params}, socket) do
    %{course: course, lesson: lesson, selected_option: option} = socket.assigns

    case Content.update_step_option(option, option_params) do
      {:ok, _option} ->
        {:noreply, push_navigate(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not update option!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({Upload, :step_img, new_path}, socket) do
    %{course: course, lesson: lesson, lesson_steps: lesson_steps} = socket.assigns

    attrs = %{lesson_id: lesson.id, kind: :image, content: new_path, order: length(lesson_steps) + 1}

    case Content.create_lesson_step(attrs) do
      {:ok, _lesson_step} ->
        {:noreply, push_navigate(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}")}

      {:error, _changeset} ->
        socket = put_flash(socket, :error, dgettext("orgs", "Could not update option!"))

        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({Upload, :option_img, new_path}, socket) do
    %{course: course, lesson: lesson, selected_option: option} = socket.assigns

    case Content.update_step_option(option, %{image: new_path}) do
      {:ok, _option} ->
        {:noreply, push_navigate(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not update option!"))}
    end
  end

  defp handle_create_step(socket, lesson_steps, _attrs) when length(lesson_steps) >= 20 do
    {:noreply, put_flash(socket, :error, dgettext("orgs", "You cannot have more than 20 steps in a lesson"))}
  end

  defp handle_create_step(socket, lesson_steps, attrs) do
    case Content.create_lesson_step(attrs) do
      {:ok, lesson_step} ->
        new_lesson_step = Map.put(lesson_step, :options, [])

        socket =
          socket
          |> assign(lesson_steps: lesson_steps ++ [new_lesson_step])
          |> assign(step_form: to_form(Content.change_lesson_step(%LessonStep{})))

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> put_flash(:error, dgettext("orgs", "Could not create step!"))
          |> assign(step_form: to_form(changeset))

        {:noreply, socket}
    end
  end
end
