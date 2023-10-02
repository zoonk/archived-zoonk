defmodule UneebeeWeb.Live.Dashboard.LessonEdit do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Content
  alias Uneebee.Content.Lesson

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{lesson: lesson} = socket.assigns
    changeset = Content.change_lesson(lesson)

    socket =
      socket
      |> assign(:page_title, lesson.name)
      |> assign(:form, to_form(changeset))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"lesson" => lesson_params}, socket) do
    changeset = %Lesson{} |> Content.change_lesson(lesson_params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"lesson" => lesson_params}, socket) do
    %{lesson: lesson} = socket.assigns

    case Content.update_lesson(lesson, lesson_params) do
      {:ok, updated_lesson} ->
        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "Lesson updated successfully!"))
          |> assign(lesson: updated_lesson)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not update lesson!"))}
    end
  end
end
