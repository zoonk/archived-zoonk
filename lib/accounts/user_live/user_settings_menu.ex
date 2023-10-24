defmodule UneebeeWeb.Live.UserSettingsMenu do
  @moduledoc false
  use UneebeeWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: gettext("Settings"))}
  end
end
