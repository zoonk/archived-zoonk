defmodule Uneebee.BillingTest do
  use Uneebee.DataCase, async: true

  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Organizations

  alias Uneebee.Billing
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
end
