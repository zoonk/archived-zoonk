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

    {:ok, %Session{} = session} =
      Session.create(%{
        mode: :subscription,
        customer: customer_id,
        success_url: billing_url,
        cancel_url: billing_url,
        client_reference_id: school.id,
        line_items: [%{price: price_id}],
        metadata: %{"school_id" => school.id, "user_id" => user.id, "plan" => "flexible"}
      })

    Phoenix.Controller.redirect(conn, external: session.url)
  end
end
