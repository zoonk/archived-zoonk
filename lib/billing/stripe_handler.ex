defmodule Uneebee.Billing.StripeHandler do
  @moduledoc """
  This module is responsible for handling Stripe events.

  It's used along with the `Stripe.WebhookPlug` plug in the endpoint configuration.
  It implements the `Stripe.WebhookHandler` behaviour.
  """
  @behaviour Stripe.WebhookHandler

  @impl Stripe.WebhookHandler
  def handle_event(_event), do: :ok
end
