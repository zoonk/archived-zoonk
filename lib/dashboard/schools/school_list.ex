defmodule UneebeeWeb.Live.Dashboard.SchoolList do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Organizations

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(page_title: dgettext("orgs", "All schools"))
      |> assign(page: 1, per_page: 10)
      |> paginate(1)

    {:ok, socket}
  end

  defp paginate(socket, new_page) when new_page >= 1 do
    %{per_page: per_page, school: school} = socket.assigns
    schools = Organizations.list_schools(school.id, offset: (new_page - 1) * per_page, limit: per_page)
    paginate(socket, new_page, schools)
  end

  @impl Phoenix.LiveView
  def handle_event("next-page", _params, socket) do
    {:noreply, paginate(socket, socket.assigns.page + 1)}
  end

  def handle_event("prev-page", %{"_overran" => true}, socket) do
    {:noreply, paginate(socket, 1)}
  end

  def handle_event("prev-page", _params, socket) do
    if socket.assigns.page > 1 do
      {:noreply, paginate(socket, socket.assigns.page - 1)}
    else
      {:noreply, socket}
    end
  end

  defp paginate(socket, new_page, schools) do
    %{per_page: per_page, page: cur_page} = socket.assigns

    {schools, at, limit} =
      if new_page >= cur_page do
        {schools, -1, per_page * 3 * -1}
      else
        {Enum.reverse(schools), 0, per_page * 3}
      end

    case schools do
      [] ->
        assign(socket, end_of_timeline?: at == -1)

      [_ | _] = schools ->
        socket
        |> assign(end_of_timeline?: false)
        |> assign(:page, new_page)
        |> stream(:schools, schools, at: at, limit: limit)
    end
  end
end
