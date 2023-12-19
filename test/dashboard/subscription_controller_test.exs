defmodule UneebeeWeb.SubscriptionControllerTest do
  use UneebeeWeb.ConnCase, async: true

  describe "GET /dashboard/billing/:price_id (non-authenticated users)" do
    setup :set_school

    test "redirects to login page", %{conn: conn} do
      conn = get(conn, ~p"/dashboard/billing/price_1Iu2Z2JY6qyq4Z2Z")
      assert redirected_to(conn) == ~p"/users/login"
    end
  end

  describe "GET /dashboard/billing/:price_id (students)" do
    setup :app_setup

    test "returns 403", %{conn: conn} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/billing/price_1Iu2Z2JY6qyq4Z2Z") end)
    end
  end

  describe "GET /dashboard/billing/:price_id (teachers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :teacher)
    end

    test "returns 403", %{conn: conn} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/billing/price_1Iu2Z2JY6qyq4Z2Z") end)
    end
  end

  describe "GET /dashboard/billing/:price_id (managers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :manager)
    end

    test "redirects to the checkout page", %{conn: conn} do
      conn = get(conn, ~p"/dashboard/billing/price_1Iu2Z2JY6qyq4Z2Z")
      assert redirected_to(conn) =~ "/pay/c/cs_test_"
    end
  end
end
