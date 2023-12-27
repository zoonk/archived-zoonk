defmodule UneebeeWeb.Live.Dashboard.SchoolView do
  @moduledoc false
  use UneebeeWeb, :live_view

  import UneebeeWeb.Billing.Utils

  alias Phoenix.LiveView.Socket
  alias Uneebee.Billing
  alias Uneebee.Billing.Subscription
  alias Uneebee.Organizations

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    %{school: school} = socket.assigns

    current_school = Organizations.get_school!(params["id"])

    if school.id != current_school.school_id, do: raise(UneebeeWeb.PermissionError, code: :permission_denied)

    user_count = Organizations.get_school_users_count(current_school.id)
    subscription = Billing.get_subscription_by_school_id(current_school.id)
    subscription_changeset = subscription_changeset(subscription)

    socket =
      socket
      |> assign(page_title: current_school.name)
      |> assign(:current_school, current_school)
      |> assign(:user_count, user_count)
      |> assign(:subscription, subscription)
      |> assign(:subscription_form, to_form(subscription_changeset))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("change_subscription", %{"subscription" => subscription_params}, %Socket{assigns: %{subscription: nil}} = socket) do
    %{current_school: current_school} = socket.assigns

    attrs = Map.put(subscription_params, "school_id", current_school.id)

    case Billing.create_subscription(attrs) do
      {:ok, subscription} ->
        socket =
          socket
          |> assign(:subscription, subscription)
          |> assign(:subscription_form, to_form(subscription_changeset(subscription)))
          |> put_flash(:info, dgettext("orgs", "Subscription updated"))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :subscription_form, to_form(changeset))}
    end
  end

  def handle_event("change_subscription", %{"subscription" => subscription_params}, socket) do
    %{subscription: subscription} = socket.assigns

    case Billing.update_subscription(subscription, subscription_params) do
      {:ok, subscription} ->
        socket =
          socket
          |> assign(:subscription, subscription)
          |> assign(:subscription_form, to_form(subscription_changeset(subscription)))
          |> put_flash(:info, dgettext("orgs", "Subscription updated"))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :subscription_form, to_form(changeset))}
    end
  end

  def handle_event("delete_school", _params, socket) do
    %{current_school: current_school} = socket.assigns

    case Organizations.delete_school(current_school) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "School deleted"))
          |> push_navigate(to: ~p"/dashboard/schools")

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "School could not be deleted"))}
    end
  end

  defp subscription_changeset(nil), do: Billing.change_subscription(%Subscription{})
  defp subscription_changeset(subscription), do: Billing.change_subscription(subscription)
end
