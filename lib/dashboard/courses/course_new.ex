defmodule UneebeeWeb.Live.Dashboard.CourseNew do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Content
  alias Uneebee.Content.Course

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    changeset = Content.change_course(%Course{})
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

    params =
      course_params
      |> Map.put("school_id", school.id)
      |> Map.put("language", user.language)

    case Content.create_course(params, user) do
      {:ok, course} ->
        socket =
          socket
          |> put_flash(:info, dgettext("courses", "Course created successfully"))
          |> push_navigate(to: ~p"/dashboard/c/#{course.slug}")

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
