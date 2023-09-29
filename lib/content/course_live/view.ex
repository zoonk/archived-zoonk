defmodule UneebeeWeb.Live.Content.Course.View do
  @moduledoc false
  use UneebeeWeb, :live_view

  import Uneebee.Content.Course.Config

  alias Uneebee.Content

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{course: course, current_user: user} = socket.assigns

    lessons = Content.list_published_lessons(course, user)
    student_count = Content.get_course_students_count(course)

    socket =
      socket
      |> assign(:page_title, course.name)
      |> assign(:student_count, student_count)
      |> assign(:lessons, lessons)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("enroll", _params, %{assigns: %{current_user: nil}} = socket) do
    {:noreply, redirect(socket, to: ~p"/users/login")}
  end

  @impl Phoenix.LiveView
  def handle_event("enroll", _params, socket) do
    %{course: course, current_user: user} = socket.assigns
    attrs = course_user_attrs(course, user)

    case Content.create_course_user(course, user, attrs) do
      {:ok, course_user} ->
        socket = socket |> assign(:course_user, course_user) |> put_flash(:info, enroll_sucess_msg(course_user))

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, dgettext("courses", "Failed to enroll"))}
    end
  end

  defp course_user_attrs(%{public?: false}, _user) do
    %{role: :student, approved?: false}
  end

  defp course_user_attrs(%{public?: true}, user) do
    %{role: :student, approved?: true, approved_by_id: user.id, approved_at: DateTime.utc_now()}
  end

  defp lesson_locked?(course_user), do: is_nil(course_user) or not course_user.approved?

  defp enroll_sucess_msg(%{approved?: true}), do: dgettext("courses", "Enrolled successfully!")
  defp enroll_sucess_msg(_cu), do: dgettext("courses", "A request to enroll has been sent to the course teacher.")

  defp lesson_link(true, _course, _lesson), do: nil
  defp lesson_link(_locked, course, lesson), do: ~p"/c/#{course.slug}/#{lesson.id}"
end
