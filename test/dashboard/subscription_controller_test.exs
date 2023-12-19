defmodule UneebeeWeb.SubscriptionControllerTest do
  use UneebeeWeb.ConnCase, async: true

  describe "GET /dashboard/subscribe (non-authenticated users)" do
    setup :set_school

    test "redirects to login page", %{conn: conn} do
      conn = get(conn, ~p"/dashboard/subscribe")
      assert redirected_to(conn) == ~p"/users/login"
    end
  end

  describe "GET /dashboard/subscribe (students)" do
    setup :app_setup

    test "returns 403", %{conn: conn} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/subscribe") end)
    end
  end

  describe "GET /dashboard/subscribe (teachers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :teacher)
    end

    test "returns 403", %{conn: conn} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/subscribe") end)
    end
  end

  describe "GET /dashboard/subscribe (managers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :manager)
    end

    test "redirects to the checkout page", %{conn: conn} do
      conn = get(conn, ~p"/dashboard/subscribe")
      assert redirected_to(conn) =~ "/pay/c/cs_test_"
    end
  end
end
