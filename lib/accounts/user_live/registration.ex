defmodule UneebeeWeb.Live.Accounts.User.Registration do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Accounts
  alias Uneebee.Accounts.User

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    locale = Map.get(session, "locale")
    changeset = Accounts.change_user_registration(%User{language: locale})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)
      |> assign(page_title: dgettext("auth", "Create an account"))

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} = Accounts.deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))

        changeset = Accounts.change_user_registration(user)
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
