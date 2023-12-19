defmodule UneebeeWeb.Live.Dashboard.SchoolBilling do
  @moduledoc false
  use UneebeeWeb, :live_view

  import UneebeeWeb.Billing.Utils
  import UneebeeWeb.Shared.Utilities

  alias Uneebee.Billing
  alias Uneebee.Billing.Subscription

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{school: school} = socket.assigns

    subscription = Billing.get_subscription_by_school_id(school.id)
    flexible_pricing = Billing.get_subscription_price("uneebee_flexible")
    currency = flexible_pricing.default

    socket =
      socket
      |> assign(:subscription, subscription)
      |> assign(:flexible_pricing, flexible_pricing)
      |> assign(:currency, String.to_existing_atom(currency))
      |> assign(:page_title, dgettext("orgs", "Billing"))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("change-currency", params, socket) do
    {:noreply, assign(socket, currency: String.to_existing_atom(params["currency"]))}
  end

  defp get_price(:free, _pricing, _currency), do: dgettext("orgs", "Free")
  defp get_price(:flexible, flexible, currency), do: round_currency(flexible.currency_options[currency])
  defp get_price(:enterprise, _pricing, _currency), do: dgettext("orgs", "Contact us")

  defp current_plan?(:free, nil), do: true
  defp current_plan?(_plan, nil), do: false
  defp current_plan?(plan, subscription), do: subscription.plan == plan

  defp buy_label(:free, nil), do: dgettext("orgs", "Current plan")
  defp buy_label(:free, %Subscription{plan: :free}), do: dgettext("orgs", "Current plan")
  defp buy_label(:free, _subscription), do: dgettext("orgs", "Downgrade")

  defp buy_label(:flexible, nil), do: dgettext("orgs", "Upgrade")
  defp buy_label(:flexible, %Subscription{plan: :flexible}), do: dgettext("orgs", "Current plan")
  defp buy_label(:flexible, %Subscription{plan: :free}), do: dgettext("orgs", "Upgrade")
  defp buy_label(:flexible, %Subscription{plan: :enterprise}), do: dgettext("orgs", "Downgrade")

  defp buy_label(:enterprise, nil), do: gettext("Contact us")
  defp buy_label(:enterprise, %Subscription{plan: :enterprise}), do: dgettext("orgs", "Current plan")
  defp buy_label(:enterprise, _subscription), do: gettext("Contact us")

  defp buy_link(:free, nil, _currency, _price), do: "#"
  defp buy_link(:free, %Subscription{plan: :free}, _currency, _price), do: "#"
  defp buy_link(:free, %Subscription{plan: plan}, currency, price_id), do: ~p"/dashboard/billing/#{plan}/free/#{currency}/#{price_id}"

  defp buy_link(:flexible, nil, currency, price_id), do: ~p"/dashboard/billing/free/flexible/#{currency}/#{price_id}"
  defp buy_link(:flexible, %Subscription{plan: :flexible}, _currency, _price), do: "#"
  defp buy_link(:flexible, %Subscription{plan: :free}, currency, price_id), do: ~p"/dashboard/billing/free/flexible/#{currency}/#{price_id}"
  defp buy_link(:flexible, %Subscription{plan: :enterprise}, currency, price_id), do: ~p"/dashboard/billing/enterprise/flexible/#{currency}/#{price_id}"

  defp buy_link(:enterprise, %Subscription{plan: :enterprise}, _currency, _price), do: "#"
  defp buy_link(:enterprise, _subscription, _currency, _price), do: ~p"/contact"
end
