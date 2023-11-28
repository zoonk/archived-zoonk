defmodule UneebeeWeb.Live.UserSettings do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Accounts
  alias UneebeeWeb.Components.Upload

  # When users change their email address, we send them a link to confirm their new email.
  # That link contains a `token` parameter that we use to confirm their email when they
  # visit the settings page using that token.
  @impl Phoenix.LiveView
  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok -> put_flash(socket, :info, dgettext("auth", "Email changed successfully."))
        :error -> put_flash(socket, :error, dgettext("auth", "Email change link is invalid or it has expired."))
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings/email")}
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{current_user: user, live_action: live_action} = socket.assigns

    changeset = get_changeset(live_action, user)

    socket =
      socket
      |> assign(:page_title, get_page_title(live_action))
      |> assign(:current_password, nil)
      |> assign(:form, to_form(changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"user" => user_params}, socket) when socket.assigns.live_action == :profile do
    settings_form =
      socket.assigns.current_user
      |> Accounts.change_user_settings(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: settings_form)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"current_password" => password, "user" => user_params}, socket) when socket.assigns.live_action == :email do
    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: email_form, current_password: password)}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"current_password" => password, "user" => user_params}, socket) when socket.assigns.live_action == :password do
    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, form: password_form, current_password: password)}
  end

  @impl Phoenix.LiveView
  def handle_event("update", %{"user" => user_params}, socket) when socket.assigns.live_action == :profile do
    user = socket.assigns.current_user
    changeset = Accounts.change_user_settings(user, user_params)
    changed_language? = Map.has_key?(changeset.changes, :language)

    case Accounts.update_user_settings(user, user_params) do
      {:ok, updated_user} ->
        if changed_language?, do: Gettext.put_locale(UneebeeWeb.Gettext, user_params["language"])

        socket =
          socket
          |> assign(form: to_form(changeset))
          |> assign(current_user: updated_user)
          |> put_flash(:info, dgettext("auth", "Settings updated successfully"))
          |> push_navigate(to: ~p"/users/settings")

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> put_flash(:error, dgettext("auth", "Error updating settings"))
          |> assign(form: to_form(changeset))

        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("update", %{"current_password" => password, "user" => user_params}, socket) when socket.assigns.live_action == :email do
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        send_email_confirmation(applied_user, user.email, socket.assigns.app)

        info = dgettext("auth", "A link to confirm your email change has been sent to the new address.")

        {:noreply, socket |> put_flash(:info, info) |> assign(current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("update", %{"current_password" => password, "user" => user_params}, socket) when socket.assigns.live_action == :password do
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form = user |> Accounts.change_user_password(user_params) |> to_form()

        {:noreply, assign(socket, trigger_submit: true, form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({Upload, :user_avatar, new_path}, socket) do
    case Accounts.update_user_settings(socket.assigns.current_user, %{avatar: new_path}) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(current_user: updated_user)
         |> put_flash(:info, gettext("Avatar updated successfully!"))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Could not update avatar!"))}
    end
  end

  defp send_email_confirmation(user, current_email, app) do
    Accounts.deliver_user_update_email_instructions(user, app, current_email, &url(~p"/users/settings/confirm_email/#{&1}"))

    if user.guest? do
      Accounts.deliver_user_reset_password_instructions(user, app, &url(~p"/users/reset_password/#{&1}"))
    end
  end

  defp get_changeset(:profile, user), do: Accounts.change_user_settings(user)
  defp get_changeset(:email, user), do: Accounts.change_user_email(user)
  defp get_changeset(:password, user), do: Accounts.change_user_password(user)
  defp get_changeset(_live_action, user), do: Accounts.change_user_settings(user)

  defp get_page_title(:profile), do: gettext("Change profile")
  defp get_page_title(:email), do: gettext("Change email")
  defp get_page_title(:password), do: gettext("Change password")
  defp get_page_title(:avatar), do: gettext("Avatar")
  defp get_page_title(_live_action), do: gettext("Settings")
end
