defmodule UneebeeWeb.Live.Dashboard.SchoolView do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Organizations

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    current_school = Organizations.get_school!(params["id"])

    socket =
      socket
      |> assign(page_title: current_school.name)
      |> assign(:current_school, current_school)

    {:ok, socket}
  end
end
