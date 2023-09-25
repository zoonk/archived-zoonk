defmodule UneebeeWeb.Live.Dashboard.Home do
  @moduledoc false
  use UneebeeWeb, :live_view

  import UneebeeWeb.Components.Dashboard.ItemStatsCard

  alias Uneebee.Organizations

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{school: school} = socket.assigns

    manager_count = Organizations.get_school_users_count(school, :manager)
    teacher_count = Organizations.get_school_users_count(school, :teacher)
    student_count = Organizations.get_school_users_count(school, :student)

    socket =
      socket
      |> assign(:page_title, gettext("Dashboard"))
      |> assign(:manager_count, manager_count)
      |> assign(:teacher_count, teacher_count)
      |> assign(:student_count, student_count)

    {:ok, socket}
  end
end
