defmodule UneebeeWeb.Components.Dashboard.LessonEdit do
  @moduledoc false
  use UneebeeWeb, :live_component

  alias Uneebee.Content
  alias Uneebee.Content.Lesson

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="mt-16 flex flex-col items-center justify-between gap-8 rounded-2xl lg:flex-row">
      <div class="flex items-center gap-2">
        <.link_button icon="tabler-edit" color={:black_light} navigate={~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/s/#{@step_order}/edit_step"}>
          <%= dgettext("orgs", "Edit lesson") %>
        </.link_button>

        <.link_button icon="tabler-photo" color={:info_light} navigate={~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/s/#{@step_order}/cover"}>
          <%= dgettext("orgs", "Cover") %>
        </.link_button>
      </div>

      <.button
        icon="tabler-trash"
        phx-click="delete-lesson"
        color={:alert}
        phx-target={@myself}
        data-confirm={dgettext("orgs", "All content from this lesson will be deleted. This action cannot be undone.")}
      >
        <%= dgettext("orgs", "Delete lesson") %>
      </.button>

      <.modal :if={@action == :edit_step} id="edit-step-modal" show on_cancel={JS.patch(~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/s/#{@step_order}")}>
        <.simple_form for={@lesson_form} id="lesson-form" unstyled phx-change="validate" phx-submit="save" phx-target={@myself}>
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
        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "Lesson updated successfully!"))
          |> push_patch(to: lesson_link(course, updated_lesson, step_order))

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not update lesson!"))}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("delete-lesson", _params, socket) do
    %{lesson: lesson, course: course} = socket.assigns

    case Content.delete_lesson(lesson) do
      {:ok, _lesson} ->
        first_lesson = Content.get_first_lesson(course)

        {:noreply, push_navigate(socket, to: lesson_link(course, first_lesson, 1))}

      {:error, _changeset} ->
        {:noreply, put_flash!(socket, :error, dgettext("orgs", "Could not delete lesson!"))}
    end
  end

  defp lesson_link(course, nil, _order), do: ~p"/dashboard/c/#{course.slug}"
  defp lesson_link(course, lesson, order), do: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{order}"
end
