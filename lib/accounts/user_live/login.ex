defmodule UneebeeWeb.Live.Accounts.User.Login do
  @moduledoc false
  use UneebeeWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    socket = socket |> assign(form: form) |> assign(page_title: dgettext("auth", "Sign in"))
    {:ok, socket, temporary_assigns: [form: form]}
  end
end
