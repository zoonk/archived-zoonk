defmodule ZoonkWeb.Live.Dashboard.CourseNew do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Content
  alias Zoonk.Content.Course

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    changeset = Content.change_course(%Course{language: session["locale"]})
    socket = socket |> assign(:page_title, dgettext("orgs", "Create a course")) |> assign(:form, to_form(changeset))
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"course" => course_params}, socket) do
    school = socket.assigns.school

    changeset =
      %Course{school_id: school.id}
      |> Content.change_course(course_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"course" => course_params}, socket) do
    school = socket.assigns.school
    user = socket.assigns.current_user
    params = Map.put(course_params, "school_id", school.id)

    case Content.create_course(params, user) do
      {:ok, course} ->
        {:noreply, push_navigate(socket, to: ~p"/dashboard/c/#{course.slug}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
