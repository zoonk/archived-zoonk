defmodule UneebeeWeb.Live.Accounts.User.Settings do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Accounts

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
    user = socket.assigns.current_user

    # We have separate forms for settings, email, and password changes.
    settings_changeset = Accounts.change_user_settings(user)
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)

    socket =
      socket
      |> assign(:page_title, gettext("Settings"))
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:settings_form, to_form(settings_changeset))
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate_settings", %{"user" => user_params}, socket) do
    settings_form =
      socket.assigns.current_user
      |> Accounts.change_user_settings(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, settings_form: settings_form)}
  end

  @impl Phoenix.LiveView
  def handle_event("update_settings", %{"user" => user_params}, socket) do
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

        {:noreply, socket}

      {:error, changeset} ->
        socket =
          socket
          |> put_flash(:error, dgettext("auth", "Error updating settings"))
          |> assign(settings_form: to_form(changeset))

        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("validate_email", %{"current_password" => password, "user" => user_params}, socket) do
    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  @impl Phoenix.LiveView
  def handle_event("update_email", %{"current_password" => password, "user" => user_params}, socket) do
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(applied_user, socket.assigns.host_school, user.email, &url(~p"/users/settings/confirm_email/#{&1}"))

        info = dgettext("auth", "A link to confirm your email change has been sent to the new address.")

        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("validate_password", %{"current_password" => password, "user" => user_params}, socket) do
    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  @impl Phoenix.LiveView
  def handle_event("update_password", %{"current_password" => password, "user" => user_params}, socket) do
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form = user |> Accounts.change_user_password(user_params) |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end
