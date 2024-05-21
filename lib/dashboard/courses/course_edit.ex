defmodule ZoonkWeb.Live.Dashboard.CourseEdit do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Content
  alias ZoonkWeb.Components.DeleteItem
  alias ZoonkWeb.Components.Upload

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{course: course} = socket.assigns
    changeset = Content.change_course(course)

    socket =
      socket
      |> assign(:page_title, dgettext("orgs", "Edit course"))
      |> assign(:form, to_form(changeset))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"course" => course_params}, socket) do
    changeset =
      socket.assigns.course
      |> Content.change_course(course_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"course" => course_params}, socket) do
    %{course: course} = socket.assigns

    case Content.update_course(course, course_params) do
      {:ok, updated_course} ->
        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "Course updated successfully!"))
          |> assign(course: updated_course)

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({DeleteItem}, socket) do
    %{course: course} = socket.assigns

    case Content.delete_course(course) do
      {:ok, _course} ->
        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "Course deleted successfully!"))
          |> push_navigate(to: ~p"/dashboard/courses")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not delete course!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({Upload, :course_cover, new_path}, socket) do
    case Content.update_course(socket.assigns.course, %{cover: new_path}) do
      {:ok, course} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("orgs", "Cover updated successfully!"))
         |> assign(course: course)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not update cover!"))}
    end
  end
end
