defmodule UneebeeWeb.Live.ForgotPassword do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Accounts

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket = socket |> assign(form: to_form(%{}, as: "user")) |> assign(page_title: dgettext("auth", "Reset Password"))
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(user, socket.assigns.app, &url(~p"/users/reset_password/#{&1}"))
    end

    {:noreply,
     socket
     |> put_flash(:info, dgettext("auth", "If your email is in our system, you will receive instructions to reset your password shortly."))
     |> redirect(to: ~p"/users/login")}
  end
end
