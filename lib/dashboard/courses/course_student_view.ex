defmodule UneebeeWeb.Live.Dashboard.CourseStudentView do
  @moduledoc false
  use UneebeeWeb, :live_view

  import UneebeeWeb.Shared.Accounts
  import UneebeeWeb.Shared.Age

  alias Uneebee.Accounts
  alias Uneebee.Content
  alias Uneebee.Content.CourseUtils

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    %{course: course} = socket.assigns

    student = Accounts.get_user_by_username(params["username"])
    full_name = "#{student.first_name} #{student.last_name}"

    lessons = Content.list_published_lessons(course, student, selections?: true)

    socket = socket |> assign(:page_title, full_name) |> assign(:student, student) |> assign(:lessons, lessons)

    {:ok, socket}
  end
end
