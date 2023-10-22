defmodule UneebeeWeb.Live.Accounts.User.Confirmation do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Accounts

  @impl Phoenix.LiveView
  def mount(%{"token" => token}, _session, socket) do
    form = to_form(%{"token" => token}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: nil]}
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  @impl Phoenix.LiveView
  def handle_event("confirm_account", %{"user" => %{"token" => token}}, socket) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        {:noreply, socket |> put_flash(:info, "User confirmed successfully.") |> redirect(to: ~p"/")}

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            {:noreply, redirect(socket, to: ~p"/")}

          %{} ->
            {:noreply, socket |> put_flash(:error, "User confirmation link is invalid or it has expired.") |> redirect(to: ~p"/users/login")}
        end
    end
  end
end
