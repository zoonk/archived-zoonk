defmodule UneebeeWeb.Components.Dashboard.LessonEdit do
  @moduledoc false
  use UneebeeWeb, :live_component

  alias Uneebee.Content
  alias Uneebee.Content.Lesson

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex items-center gap-x-2">
        <.link_button id="lesson-cover-link" icon="tabler-photo" color={:white} navigate={~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/s/#{@step_order}/cover"}>
          <%= dgettext("orgs", "Cover") %>
        </.link_button>

        <.link_button icon="tabler-edit" color={:white} navigate={~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/s/#{@step_order}/edit_step"}>
          <%= gettext("Edit") %>
        </.link_button>
      </div>

      <.modal :if={@action == :edit_step} id="edit-step-modal" show on_cancel={JS.patch(~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/s/#{@step_order}")}>
        <.simple_form for={@lesson_form} id="lesson-form" unstyled phx-change="validate" phx-submit="save" class="space-y-8" phx-target={@myself}>
          <.input type="text" field={@lesson_form[:name]} label={dgettext("orgs", "Lesson name")} required />
          <.input type="text" field={@lesson_form[:description]} label={dgettext("orgs", "Lesson description")} required />

          <:actions>
            <.button type="submit" icon="tabler-check" phx-disable-with={gettext("Saving...")}>
              <%= gettext("Save") %>
            </.button>
          </:actions>
        </.simple_form>
      </.modal>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    changeset = Content.change_lesson(assigns.lesson)
    socket = socket |> assign(assigns) |> assign(:lesson_form, to_form(changeset))
    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", %{"lesson" => lesson_params}, socket) do
    changeset = %Lesson{} |> Content.change_lesson(lesson_params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, lesson_form: to_form(changeset))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"lesson" => lesson_params}, socket) do
    %{lesson: lesson, step_order: step_order, course: course} = socket.assigns

    case Content.update_lesson(lesson, lesson_params) do
      {:ok, updated_lesson} ->
        notify_parent(socket, updated_lesson)

        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "Lesson updated successfully!"))
          |> push_patch(to: lesson_link(course, updated_lesson, step_order))

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not update lesson!"))}
    end
  end

  defp lesson_link(course, lesson, order), do: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{order}"

  defp notify_parent(socket, updated_lesson) do
    send(self(), {__MODULE__, :lesson_edit, %{socket | assigns: %{socket.assigns | lesson: Map.merge(socket.assigns.lesson, updated_lesson)}}})
    :ok
  end
end
