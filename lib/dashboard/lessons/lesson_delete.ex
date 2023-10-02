defmodule UneebeeWeb.Live.Dashboard.LessonDelete do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Content
  alias UneebeeWeb.Components.DeleteItem

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket = assign(socket, :page_title, dgettext("orgs", "Delete lesson"))
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({DeleteItem}, socket) do
    %{lesson: lesson, course: course} = socket.assigns

    case Content.delete_lesson(lesson) do
      {:ok, _lesson} ->
        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "Lesson deleted successfully!"))
          |> push_navigate(to: ~p"/dashboard/c/#{course.slug}")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not delete lesson!"))}
    end
  end
end
