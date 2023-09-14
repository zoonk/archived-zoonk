defmodule UneebeeWeb.Live.Accounts.User.Login do
  @moduledoc false
  use UneebeeWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
