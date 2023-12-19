defmodule UneebeeWeb.StripeHandlerTest do
  use UneebeeWeb.ConnCase, async: true

  import Uneebee.Fixtures.Billing
  import Uneebee.Fixtures.Organizations

  alias Uneebee.Billing
  alias Uneebee.Billing.StripeHandler

  describe "checkout.session.completed" do
    test "creates a subscription if a school doesn't have one yet" do
      school = school_fixture()

      assert Billing.get_subscription_by_school_id(school.id) == nil

      params = %Stripe.Event{
        type: "checkout.session.completed",
        data: %{
          object: %Stripe.Checkout.Session{
            client_reference_id: school.id,
            payment_status: "unpaid",
            payment_intent: "pi_mockintent",
            metadata: %{"plan" => "flexible"}
          }
        }
      }

      assert StripeHandler.handle_event(params) == :ok
      assert Billing.get_subscription_by_school_id(school.id) != nil
    end

    test "updates an existing subscription" do
      subscription = subscription_fixture(%{payment_status: :pending, paid_at: nil})

      params = %Stripe.Event{
        type: "checkout.session.completed",
        data: %{
          object: %Stripe.Checkout.Session{
            client_reference_id: subscription.school_id,
            payment_status: "paid",
            payment_intent: "pi_mockintent",
            metadata: %{"plan" => "flexible"}
          }
        }
      }

      assert StripeHandler.handle_event(params) == :ok

      updated_subscription = Billing.get_subscription_by_school_id(subscription.school_id)
      assert updated_subscription.payment_status == :confirmed
      assert updated_subscription.paid_at != nil
    end
  end

  describe "checkout.session.async_payment_failed" do
    test "updates an existing subscription" do
      subscription = subscription_fixture(%{payment_status: :pending, paid_at: nil})

      params = %Stripe.Event{
        type: "checkout.session.async_payment_failed",
        data: %{
          object: %Stripe.Checkout.Session{
            client_reference_id: subscription.school_id,
            payment_status: "unpaid",
            payment_intent: "pi_mockintent",
            metadata: %{"plan" => "flexible"}
          }
        }
      }

      assert StripeHandler.handle_event(params) == :ok

      updated_subscription = Billing.get_subscription_by_school_id(subscription.school_id)
      assert updated_subscription.payment_status == :error
      assert updated_subscription.paid_at == nil
    end
  end

  describe "checkout.session.async_payment_succeeded" do
    test "updates an existing subscription" do
      subscription = subscription_fixture(%{payment_status: :pending, paid_at: nil})

      params = %Stripe.Event{
        type: "checkout.session.async_payment_succeeded",
        data: %{
          object: %Stripe.Checkout.Session{
            client_reference_id: subscription.school_id,
            payment_status: "paid",
            payment_intent: "pi_mockintent",
            metadata: %{"plan" => "flexible"}
          }
        }
      }

      assert StripeHandler.handle_event(params) == :ok

      updated_subscription = Billing.get_subscription_by_school_id(subscription.school_id)
      assert updated_subscription.payment_status == :confirmed
      assert updated_subscription.paid_at != nil
    end
  end

  describe "unhandled event" do
    test "returns :ok" do
      params = %Stripe.Event{
        type: "unhandled.event",
        data: %{
          object: %Stripe.Checkout.Session{
            client_reference_id: "school_id",
            payment_status: "paid",
            payment_intent: "pi_mockintent",
            metadata: %{"plan" => "flexible"}
          }
        }
      }

      assert StripeHandler.handle_event(params) == :ok
    end
  end
end
