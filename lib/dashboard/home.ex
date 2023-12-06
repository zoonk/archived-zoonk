defmodule UneebeeWeb.Live.Dashboard.Home do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Organizations

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{school: school} = socket.assigns

    manager_count = Organizations.get_school_users_count(school, :manager)
    teacher_count = Organizations.get_school_users_count(school, :teacher)
    student_count = Organizations.get_school_users_count(school, :student)

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
