defmodule ZoonkWeb.Components.Dashboard.CoursePublish do
  @moduledoc false
  use ZoonkWeb, :live_component

  alias Zoonk.Content
  alias Zoonk.Content.Course

  attr :course, Course, required: true

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <header class="flex h-max justify-end">
      <.button :if={not @course.published?} phx-click="toggle-status" phx-target={@myself} icon="tabler-eye" color={:success}>
        <%= dgettext("orgs", "Publish") %>
      </.button>

      <.button :if={@course.published?} phx-click="toggle-status" phx-target={@myself} icon="tabler-eye-off" color={:alert}>
        <%= dgettext("orgs", "Unpublish") %>
      </.button>
    </header>
    """
  end

  @impl Phoenix.LiveComponent
  def handle_event("toggle-status", _params, socket) do
    %{course: course} = socket.assigns

    published? = !course.published?

    case Content.update_course(course, %{published?: published?}) do
      {:ok, updated_course} ->
        {:noreply, assign(socket, course: updated_course)}

      {:error, _changeset} ->
        {:noreply, put_flash!(socket, :error, dgettext("orgs", "Could not update course!"))}
    end
  end
end
