defmodule UneebeeWeb.Controller.SchoolSubscription do
  @moduledoc """
  Creates a new subscription for a school.

  It creates a new Stripe Checkout Session and redirects the user to the checkout page.
  """
  use UneebeeWeb, :controller

  alias Stripe.Checkout.Session
  alias Uneebee.Billing

  @spec show(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def show(conn, params) do
    %{school: school, current_user: user} = conn.assigns

    customer_id = Billing.create_stripe_customer(school, user)
    billing_url = "https://#{conn.host}/dashboard/billing"
    price_id = params["price_id"]
    from = params["from"]
    to = params["to"]
    currency = params["currency"]

    handle_subscription(conn, %{from: from, to: to, currency: currency, customer_id: customer_id, price_id: price_id, billing_url: billing_url, school: school, user: user})
  end

  # from free, then create session
  defp handle_subscription(conn, %{from: "free"} = attrs) do
    {:ok, %Session{} = session} =
      Session.create(%{
        mode: :subscription,
        customer: attrs.customer_id,
        currency: attrs.currency,
        success_url: attrs.billing_url,
        cancel_url: attrs.billing_url,
        client_reference_id: attrs.school.id,
        line_items: [%{price: attrs.price_id}],
        metadata: %{"school_id" => attrs.school.id, "user_id" => attrs.user.id, "plan" => "flexible"}
      })

    Phoenix.Controller.redirect(conn, external: session.url)
  end

  # from flexible, then delete subscription
  defp handle_subscription(conn, %{to: "free"} = attrs) do
    Billing.delete_school_subscription(attrs.school.id)
    Phoenix.Controller.redirect(conn, to: ~p"/dashboard/billing")
  end
end
