defmodule ZoonkWeb.SubscriptionControllerTest do
  use ZoonkWeb.ConnCase, async: true

  import Zoonk.Fixtures.Billing
  import Zoonk.Fixtures.Organizations

  alias Zoonk.Billing

  describe "GET /dashboard/billing/:price_id (non-authenticated users)" do
    setup :set_school

    test "redirects to login page", %{conn: conn} do
      conn = get(conn, ~p"/dashboard/billing/free/flexible/usd/pri_123")
      assert redirected_to(conn) == ~p"/users/login"
    end
  end

  describe "GET /dashboard/billing/:price_id (students)" do
    setup :app_setup

    test "returns 403", %{conn: conn} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/billing/free/flexible/usd/pri_123") end)
    end
  end

  describe "GET /dashboard/billing/:price_id (teachers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :teacher)
    end

    test "returns 403", %{conn: conn} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/billing/free/flexible/usd/pri_123") end)
    end
  end

  describe "GET /dashboard/billing/:price_id (managers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :manager)
    end

    test "redirects to the checkout page when upgrading", %{conn: conn} do
      conn = get(conn, ~p"/dashboard/billing/free/flexible/usd/pri_123")
      assert redirected_to(conn) =~ "/pay/c/cs_test_"
    end

    test "deletes the subscription when downgrading", %{conn: conn, school: school, user: user} do
      child_school = school_fixture(%{school_id: school.id})
      school_user_fixture(%{school: child_school, user: user, role: :manager})

      host = "#{child_school.slug}.#{school.custom_domain}"
      subscription_fixture(%{school_id: child_school.id})

      conn = conn |> Map.put(:host, host) |> get(~p"/dashboard/billing/flexible/free/usd/pri_123")
      assert redirected_to(conn) == ~p"/dashboard/billing"
      assert Billing.get_subscription_by_school_id(child_school.id) == nil
    end
  end
end
