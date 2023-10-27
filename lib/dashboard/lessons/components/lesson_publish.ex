defmodule UneebeeWeb.Components.Dashboard.LessonPublish do
  @moduledoc false
  use UneebeeWeb, :live_component

  alias Uneebee.Content
  alias Uneebee.Content.Lesson

  attr :lesson, Lesson, required: true

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.button :if={not @lesson.published?} phx-click="toggle-status" phx-target={@myself} icon="tabler-eye" color={:success_light}>
        <%= dgettext("orgs", "Publish") %>
      </.button>

      <.button :if={@lesson.published?} phx-click="toggle-status" phx-target={@myself} icon="tabler-eye-off" color={:alert_light}>
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
