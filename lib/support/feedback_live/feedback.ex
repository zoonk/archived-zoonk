defmodule UneebeeWeb.Live.Feedback do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Accounts.User
  alias Uneebee.Accounts.UserUtils
  alias Uneebee.Support

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{current_user: user} = socket.assigns

    socket =
      socket
      |> assign(:page_title, gettext("Feedback"))
      |> assign(:name, get_name(user))
      |> assign(:email, get_email(user))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("send", %{"name" => name, "email" => email, "message" => message}, socket) do
    case Support.send_feedback(socket.assigns.school, name, email, message) do
      {:ok, _mailer} ->
        {:noreply, put_flash(socket, :info, gettext("Feedback sent!"))}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, gettext("There was an error sending your feedback. Please try again."))}
    end
  end

  defp get_name(%User{} = user), do: UserUtils.full_name(user)
  defp get_name(_user), do: ""

  defp get_email(%User{} = user), do: user.email
  defp get_email(_user), do: ""
end
