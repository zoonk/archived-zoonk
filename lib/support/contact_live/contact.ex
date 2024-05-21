defmodule ZoonkWeb.Live.Contact do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Accounts.User
  alias Zoonk.Accounts.UserUtils
  alias Zoonk.Support

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{current_user: user} = socket.assigns

    socket =
      socket
      |> assign(:page_title, gettext("Contact us"))
      |> assign(:name, get_name(user))
      |> assign(:email, get_email(user))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("send", %{"name" => name, "email" => email, "message" => message}, socket) do
    case Support.send_feedback(socket.assigns.school, name, email, message) do
      {:ok, _mailer} ->
        {:noreply, put_flash(socket, :info, gettext("Message sent!"))}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, gettext("There was an error sending your message. Please try again."))}
    end
  end

  defp get_name(%User{} = user), do: UserUtils.full_name(user)
  defp get_name(_user), do: ""

  defp get_email(%User{} = user), do: user.email
  defp get_email(_user), do: ""
end
