defmodule ZoonkWeb.Live.Dashboard.Home do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Organizations

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{school: school} = socket.assigns

    manager_count = Organizations.get_school_users_count(school.id, :manager)
    teacher_count = Organizations.get_school_users_count(school.id, :teacher)
    student_count = Organizations.get_school_users_count(school.id, :student)

    socket =
      socket
      |> assign(:page_title, dgettext("orgs", "Dashboard"))
      |> assign(:user_count, %{manager: manager_count, teacher: teacher_count, student: student_count})

    {:ok, socket}
  end

  defp school_stats do
    [
      %{title: dgettext("orgs", "Managers"), icon: "tabler-puzzle", id: :manager},
      %{title: dgettext("orgs", "Teachers"), icon: "tabler-apple", id: :teacher},
      %{title: dgettext("orgs", "Students"), icon: "tabler-comet", id: :student}
    ]
  end
end
