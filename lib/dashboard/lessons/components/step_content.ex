defmodule ZoonkWeb.Components.Dashboard.StepContent do
  @moduledoc false
  use ZoonkWeb, :live_component

  alias Zoonk.Content
  alias Zoonk.Content.Course
  alias Zoonk.Content.Lesson
  alias Zoonk.Content.LessonStep
  alias Zoonk.Shared.YouTube

  attr :action, :atom, default: nil
  attr :course, Course, required: true
  attr :lesson, Lesson, required: true
  attr :step, LessonStep, required: true

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.link class="mb-4 flex items-center gap-1" id={"step-edit-#{@step.id}"} patch={~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/s/#{@step.order}/edit"}>
        <span class="whitespace-pre-wrap"><%= YouTube.remove_from_string(@step.content) %></span> <.icon name="tabler-edit" title={dgettext("orgs", "Edit step")} />
      </.link>

      <.youtube content={@step.content} />

      <.modal :if={@action == :edit} show id="edit-step" on_cancel={JS.patch(~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/s/#{@step.order}")}>
        <.simple_form for={@step_form} id="step-form" phx-change="validate-step" phx-target={@myself} phx-submit="update-step" class="space-y-8" unstyled>
          <.input
            type="textarea"
            field={@step_form[:content]}
            label={dgettext("orgs", "Update step")}
            helper={dgettext("orgs", "A lesson has multiple steps. Use them to tell a story, explain a concept or ask a question. Keep them short and simple.")}
            required
          />

          <:actions>
            <.button type="submit" icon="tabler-edit" phx-disable-with={gettext("Updating...")}><%= gettext("Update") %></.button>
          </:actions>
        </.simple_form>
      </.modal>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    socket =
      socket
      |> assign(action: assigns.action)
      |> assign(course: assigns.course)
      |> assign(lesson: assigns.lesson)
      |> assign(step: assigns.step)
      |> assign(step_form: to_form(Content.change_lesson_step(assigns.step)))

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate-step", %{"lesson_step" => lesson_step_params}, socket) do
    changeset = %LessonStep{} |> Content.change_lesson_step(lesson_step_params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, step_form: to_form(changeset))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("update-step", %{"lesson_step" => lesson_step_params}, socket) do
    %{course: course, lesson: lesson, step: step} = socket.assigns

    case Content.update_lesson_step(step, lesson_step_params) do
      {:ok, _lesson_step} ->
        {:noreply, push_patch(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{step.order}")}

      {:error, changeset} ->
        socket =
          socket
          |> put_flash!(:error, dgettext("orgs", "Could not update step!"))
          |> assign(step_form: to_form(changeset))

        {:noreply, socket}
    end
  end
end
