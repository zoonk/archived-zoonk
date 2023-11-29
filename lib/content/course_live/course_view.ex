defmodule UneebeeWeb.Live.CourseView do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Content
  alias Uneebee.Content.CourseUtils

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{course: course, current_user: user} = socket.assigns

    lessons = Content.list_published_lessons(course, user)
    student_count = Content.get_course_users_count(course, :student)

    socket =
      socket
      |> assign(:page_title, course.name)
      |> assign(:page_description, course.description)
      |> assign(:og_image, course.cover)
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

  defp lesson_locked?(%{public?: true}, _course_user), do: false
  defp lesson_locked?(_course, course_user), do: is_nil(course_user) or not course_user.approved?

  defp enroll_sucess_msg(%{approved?: true}), do: dgettext("courses", "Enrolled successfully!")
  defp enroll_sucess_msg(_cu), do: dgettext("courses", "A request to enroll has been sent to the course teacher.")

  defp lesson_link(true, _course, _lesson), do: nil
  defp lesson_link(_locked, course, lesson), do: ~p"/c/#{course.slug}/#{lesson.id}"

  defp lesson_color(course, course_user, user, user_lessons) do
    locked? = lesson_locked?(course, course_user)
    completed? = CourseUtils.lesson_completed?(user, user_lessons)
    score = CourseUtils.lesson_score(user, user_lessons)
    lesson_color(locked?, completed?, score)
  end

  defp lesson_color(true, _completed, _score), do: "cursor-not-allowed border-gray-400 hover:outline-gray-400 opacity-50"
  defp lesson_color(false, true, score) when score >= 8, do: "border-teal-500 hover:outline-teal-500 focus:outline-teal-500"
  defp lesson_color(false, true, score) when score >= 6, do: "border-amber-500 hover:outline-amber-500 focus:outline-amber-500"
  defp lesson_color(false, true, _score), do: "border-pink-500 hover:outline-pink-500 focus:outline-pink-500"
  defp lesson_color(false, false, _score), do: "border-gray-400 hover:outline-gray-400 focus:outline-gray-400"
end
