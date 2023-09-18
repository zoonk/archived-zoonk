defmodule UneebeeWeb.Live.Home do
  @moduledoc false
  use UneebeeWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket = assign(socket, page_title: gettext("Home"))
    {:ok, socket}
  end
end
