defmodule UneebeeWeb.Live.Dashboard.SchoolList do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Organizations

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{school: school} = socket.assigns

    schools = Organizations.list_schools(school.id)

    socket =
      socket
      |> assign(page_title: dgettext("orgs", "All schools"))
      |> stream(:schools, schools)

    {:ok, socket}
  end
end
