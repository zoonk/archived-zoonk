defmodule ZoonkWeb.Live.Dashboard.SchoolList do
  @moduledoc false
  use ZoonkWeb, :live_view
  use ZoonkWeb.Shared.Paginate, as: :schools

  alias Zoonk.Organizations

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(page_title: dgettext("orgs", "All schools"))
      |> add_pagination()

    {:ok, socket}
  end

  defp paginate(socket, new_page) when new_page >= 1 do
    %{per_page: per_page, school: school} = socket.assigns
    schools = Organizations.list_schools(school.id, offset: (new_page - 1) * per_page, limit: per_page)
    paginate(socket, new_page, schools)
  end
end
