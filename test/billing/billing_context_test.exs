defmodule Uneebee.BillingTest do
  use Uneebee.DataCase, async: true

  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Billing
  import Uneebee.Fixtures.Organizations

  alias Uneebee.Billing
  alias Uneebee.Billing.Subscription
  alias Uneebee.Organizations

  describe "create_stripe_customer/2" do
    test "creates a Stripe customer for a school" do
      school = school_fixture()
      manager = user_fixture()

      assert school.stripe_customer_id == nil

      customer_id = Billing.create_stripe_customer(school, manager)
      assert String.starts_with?(customer_id, "cus_")
      assert Organizations.get_school!(school.id).stripe_customer_id == customer_id
    end

    test "does nothing if the school already has a Stripe customer" do
      school = school_fixture(%{stripe_customer_id: "cus_123"})
      manager = user_fixture()

      customer_id = Billing.create_stripe_customer(school, manager)
      assert customer_id == "cus_123"
    end
  end

  describe "create_subscription/1" do
    test "creates a subscription for a school" do
      school = school_fixture()

      assert {:ok, %Subscription{} = subscription} = Billing.create_subscription(%{school_id: school.id})
      assert subscription.school_id == school.id
      assert subscription.plan == :free
      assert subscription.payment_status == :pending
    end

    test "doesn't allow to create multiple subscriptions for a school" do
      school = school_fixture()

      assert {:ok, %Subscription{} = subscription} = Billing.create_subscription(%{school_id: school.id})
      assert {:error, _error} = Billing.create_subscription(%{school_id: school.id})

      assert Billing.get_subscription_by_school_id(school.id) == subscription
    end
  end

  describe "update_subscription/2" do
    test "updates a subscription" do
      school = school_fixture()

      assert {:ok, %Subscription{} = subscription} = Billing.create_subscription(%{school_id: school.id})
      assert {:ok, %Subscription{} = subscription} = Billing.update_subscription(subscription, %{plan: :flexible})
      assert subscription.plan == :flexible
    end
  end

  describe "get_subscription_by_school_id/1" do
    test "gets a school's subscription" do
      school = school_fixture()

      assert {:ok, %Subscription{} = subscription} = Billing.create_subscription(%{school_id: school.id})
      assert Billing.get_subscription_by_school_id(school.id) == subscription
    end
  end

  describe "delete_school_subscription/1" do
    test "deletes a school's subscription" do
      subscription = subscription_fixture()

      assert {:ok, %Subscription{} = subscription} = Billing.delete_school_subscription(subscription.school_id)
      assert Billing.get_subscription_by_school_id(subscription.school_id) == nil
    end
  end

  describe "active_subscription?/1" do
    test "returns true if the school is the main school" do
      school = school_fixture(%{school_id: nil})
      assert Billing.active_subscription?(school)
    end

    test "returns true if the payment is confirmed" do
      parent_school = school_fixture(%{school_id: nil})
      school = school_fixture(%{school_id: parent_school.id})
      subscription_fixture(%{school_id: parent_school.id, payment_status: :confirmed})

      assert Billing.active_subscription?(school)
    end

    test "returns false if the payment is pending and the school has more than 2 users" do
      parent_school = school_fixture(%{school_id: nil})
      school = school_fixture(%{school_id: parent_school.id})
      subscription_fixture(%{school_id: parent_school.id, payment_status: :pending})

      Enum.each(1..3, fn _idx -> school_user_fixture(%{school: school}) end)

      refute Billing.active_subscription?(school)
    end

    test "returns true if the payment is pending and the school has 2 or less users" do
      parent_school = school_fixture(%{school_id: nil})
      school = school_fixture(%{school_id: parent_school.id})
      subscription_fixture(%{school_id: parent_school.id, payment_status: :pending})

      Enum.each(1..2, fn _idx -> school_user_fixture(%{school: school}) end)

      assert Billing.active_subscription?(school)
    end

    test "returns false if the payment has error and the school has more than 2 users" do
      parent_school = school_fixture(%{school_id: nil})
      school = school_fixture(%{school_id: parent_school.id})
      subscription_fixture(%{school_id: parent_school.id, payment_status: :error})

      Enum.each(1..3, fn _idx -> school_user_fixture(%{school: school}) end)

      refute Billing.active_subscription?(school)
    end

    test "returns true if the payment has error and the school has 2 or less users" do
      parent_school = school_fixture(%{school_id: nil})
      school = school_fixture(%{school_id: parent_school.id})
      subscription_fixture(%{school_id: parent_school.id, payment_status: :error})

      Enum.each(1..2, fn _idx -> school_user_fixture(%{school: school}) end)

      assert Billing.active_subscription?(school)
    end

    test "returns false if there is no subscription and the school has more than 2 users" do
      parent_school = school_fixture(%{school_id: nil})
      school = school_fixture(%{school_id: parent_school.id})

      Enum.each(1..3, fn _idx -> school_user_fixture(%{school: school}) end)

      refute Billing.active_subscription?(school)
    end

    test "returns true if there is no subscription and the school has 2 or less users" do
      parent_school = school_fixture(%{school_id: nil})
      school = school_fixture(%{school_id: parent_school.id})

      Enum.each(1..2, fn _idx -> school_user_fixture(%{school: school}) end)

      assert Billing.active_subscription?(school)
    end
  end
end
