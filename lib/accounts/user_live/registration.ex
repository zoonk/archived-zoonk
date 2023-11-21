defmodule UneebeeWeb.Live.Registration do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Phoenix.HTML
  alias Uneebee.Accounts
  alias Uneebee.Accounts.User
  alias Uneebee.Organizations
  alias Uneebee.Organizations.School

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    locale = Map.get(session, "locale")
    changeset = Accounts.change_user_registration(%User{language: locale})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)
      |> assign(page_title: dgettext("auth", "Create an account"))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        confirm_account(user, socket.assigns.host_school)

        maybe_create_school_user(user, socket.assigns.school)

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

  # This app can have multiple schools. The app's default one is defined by the `host` value.
  # When a user registers, we add them as a `student` of the app's school.
  # If the school isn't configured, then we don't add the user to any school.
  defp maybe_create_school_user(_user, nil), do: :ok

  defp maybe_create_school_user(user, school) do
    attrs = get_school_user_attrs(user, school.public?)
    Organizations.create_school_user(school, user, attrs)
  end

  # If the school is public, then automatically approved? this user.
  defp get_school_user_attrs(user, true) do
    %{role: :student, approved?: true, approved_by_id: user.id, approved_at: DateTime.utc_now()}
  end

  defp get_school_user_attrs(_user, false), do: %{role: :student}

  defp get_terms(terms_of_use) do
    "auth" |> dgettext("terms of use") |> get_terms_link(terms_of_use) |> HTML.safe_to_string()
  end

  defp get_privacy(privacy_policy) do
    "auth" |> dgettext("privacy policy") |> get_terms_link(privacy_policy) |> HTML.safe_to_string()
  end

  defp get_terms_link(label, link), do: HTML.Link.link(label, to: URI.parse(link), class: "text-indigo-500 hover:underline")

  defp terms_label(%School{terms_of_use: nil, privacy_policy: nil}), do: nil

  defp terms_label(%School{terms_of_use: terms_of_use, privacy_policy: nil}) do
    dgettext("auth", "By signing up, you agree to our %{terms}.", terms: get_terms(terms_of_use))
  end

  defp terms_label(%School{terms_of_use: nil, privacy_policy: privacy_policy}) do
    dgettext("auth", "By signing up, you agree to our %{privacy}.", privacy: get_privacy(privacy_policy))
  end

  defp terms_label(%School{terms_of_use: terms_of_use, privacy_policy: privacy_policy}) do
    dgettext("auth", "By signing up, you agree to our %{terms} and %{privacy}.",
      terms: get_terms(terms_of_use),
      privacy: get_privacy(privacy_policy)
    )
  end

  defp terms_label(_school), do: nil

  defp confirm_account(user, nil), do: Accounts.confirm_user(user)
  defp confirm_account(user, school), do: Accounts.deliver_user_confirmation_instructions(user, school, &url(~p"/users/confirm/#{&1}"))
end
