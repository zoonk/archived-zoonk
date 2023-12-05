defmodule UneebeeWeb.Live.Dashboard.CourseStudentView do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Accounts
  alias Uneebee.Accounts.UserUtils
  alias Uneebee.Content
  alias Uneebee.Content.CourseUtils

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    %{course: course} = socket.assigns

    student = Accounts.get_user_by_username(params["username"])
    course_user = Content.get_course_user_by_id(course.id, student.id)

    # Prevent from viewing users who aren't enrolled in the course
    if is_nil(course_user), do: raise(UneebeeWeb.PermissionError, code: :not_enrolled)

    full_name = UserUtils.full_name(student)
    lessons = Content.list_published_lessons(course, student, selections?: true)

    socket = socket |> assign(:page_title, full_name) |> assign(:student, student) |> assign(:lessons, lessons)

    {:ok, socket}
  end
end
