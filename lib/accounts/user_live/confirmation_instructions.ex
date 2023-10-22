defmodule UneebeeWeb.Live.ConfirmationInstructions do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Accounts

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  @impl Phoenix.LiveView
  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(user, socket.assigns.host_school, &url(~p"/users/confirm/#{&1}"))
    end

    info = "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."

    {:noreply, socket |> put_flash(:info, info) |> redirect(to: ~p"/")}
  end
end
