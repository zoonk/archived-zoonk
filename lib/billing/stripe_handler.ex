defmodule Uneebee.Billing.StripeHandler do
  @moduledoc """
  This module is responsible for handling Stripe events.

  It's used along with the `Stripe.WebhookPlug` plug in the endpoint configuration.
  It implements the `Stripe.WebhookHandler` behaviour.
  """
  @behaviour Stripe.WebhookHandler

  alias Stripe.Checkout.Session
  alias Uneebee.Billing
  alias Uneebee.Billing.Subscription
  alias Uneebee.Organizations

  @impl Stripe.WebhookHandler
  def handle_event(%Stripe.Event{type: "checkout.session.completed"} = event) do
    %{object: %Session{} = session} = event.data
    session.client_reference_id |> Billing.get_subscription_by_school_id() |> handle_subscription(session)
    :ok
  end

  def handle_event(%Stripe.Event{type: "checkout.session.async_payment_failed"} = event) do
    %{object: %Session{} = session} = event.data

    session.client_reference_id
    |> Billing.get_subscription_by_school_id()
    |> Billing.update_subscription(%{payment_status: :error})

    :ok
  end

  def handle_event(%Stripe.Event{type: "checkout.session.async_payment_succeeded"} = event) do
    %{object: %Session{} = session} = event.data

    session.client_reference_id
    |> Billing.get_subscription_by_school_id()
    |> Billing.update_subscription(%{payment_status: :confirmed, paid_at: DateTime.utc_now(), stripe_subscription_id: session.subscription})

    :ok
  end

  def handle_event(_event), do: :ok

  defp handle_subscription(nil, %Session{} = session) do
    subscription_item_id = Billing.get_subscription_item_id(session.subscription)

    Billing.create_subscription(%{
      school_id: session.client_reference_id,
      plan: String.to_existing_atom(session.metadata["plan"]),
      payment_status: get_payment_status(session.payment_status),
      stripe_payment_intent_id: session.payment_intent,
      stripe_subscription_id: session.subscription,
      stripe_subscription_item_id: subscription_item_id,
      paid_at: get_paid_at(session.payment_status)
    })

    school_users = Organizations.get_school_users_count(session.client_reference_id)
    Stripe.UsageRecord.create(subscription_item_id, %{quantity: school_users})
  end

  defp handle_subscription(%Subscription{} = subscription, %Session{} = session) do
    Billing.update_subscription(subscription, %{
      payment_status: get_payment_status(session.payment_status),
      stripe_payment_intent_id: session.payment_intent,
      stripe_subscription_id: session.subscription,
      stripe_subscription_item_id: Billing.get_subscription_item_id(session.subscription),
      paid_at: get_paid_at(session.payment_status)
    })
  end

  defp get_payment_status("unpaid"), do: :pending
  defp get_payment_status(_status), do: :confirmed

  defp get_paid_at("unpaid"), do: nil
  defp get_paid_at(_status), do: DateTime.utc_now()
end
