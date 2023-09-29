defmodule UneebeeWeb.Live.Dashboard.LessonCover do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Content
  alias UneebeeWeb.Components.Upload

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket = assign(socket, :page_title, dgettext("orgs", "Cover"))
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({Upload, :lesson_cover, new_path}, socket) do
    %{lesson: lesson} = socket.assigns

    case Content.update_lesson(lesson, %{cover: new_path}) do
      {:ok, updated_lesson} ->
        socket =
          socket
          |> put_flash(:info, dgettext("courses", "Cover updated successfully!"))
          |> assign(lesson: updated_lesson)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("courses", "Could not update cover!"))}
    end
  end
end
