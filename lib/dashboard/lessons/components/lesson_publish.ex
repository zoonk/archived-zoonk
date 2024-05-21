defmodule ZoonkWeb.Components.Dashboard.LessonPublish do
  @moduledoc false
  use ZoonkWeb, :live_component

  alias Zoonk.Content
  alias Zoonk.Content.Lesson

  attr :lesson, Lesson, required: true

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.button :if={not @lesson.published?} phx-click="toggle-status" phx-target={@myself} icon="tabler-eye">
        <%= dgettext("orgs", "Publish") %>
      </.button>

      <.button :if={@lesson.published?} phx-click="toggle-status" phx-target={@myself} icon="tabler-eye-off" color={:alert}>
        <%= dgettext("orgs", "Unpublish") %>
      </.button>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def handle_event("toggle-status", _params, socket) do
    %{lesson: lesson} = socket.assigns

    published? = !lesson.published?

    case Content.update_lesson(lesson, %{published?: published?}) do
      {:ok, updated_lesson} ->
        {:noreply, assign(socket, lesson: updated_lesson)}

      {:error, _changeset} ->
        {:noreply, put_flash!(socket, :error, dgettext("orgs", "Could not update lesson!"))}
    end
  end
end
