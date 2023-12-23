defmodule UneebeeWeb.SchoolBillingLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Mock
  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Billing

  alias Uneebee.Billing

  @subscription_price %{default: "usd", id: "pri_123", currency_options: %{usd: 10.0, eur: 9.0, brl: 49.99}}

  describe "school billing (non-authenticated users)" do
    setup :set_school

    test "redirects to login page", %{conn: conn} do
      result = get(conn, ~p"/dashboard/billing")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "school billing (students)" do
    setup :app_setup

    test "returns 403", %{conn: conn} do
      assert_error_sent 403, fn -> get(conn, ~p"/dashboard/billing") end
    end
  end

  describe "school billing (teachers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :teacher)
    end

    test "returns 403", %{conn: conn} do
      assert_error_sent 403, fn -> get(conn, ~p"/dashboard/billing") end
    end
  end

  describe "school billing (managers)" do
    setup_with_mocks([{Billing, [:passthrough], get_subscription_price: fn _plan -> @subscription_price end}]) do
      app_setup(%{conn: build_conn()}, school_user: :manager)
    end

    test "updates the currency", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard/billing")
      assert has_element?(lv, "span", "$10")

      lv |> element("#change-currency") |> render_change(%{"currency" => "eur"})
      assert has_element?(lv, "span", "€9")

      lv |> element("#change-currency") |> render_change(%{"currency" => "brl"})
      assert has_element?(lv, "span", "R$49.99")
    end

    test "displays all plans when there's no existing subscription", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard/billing")

      assert has_element?(lv, "h3", "Hobby")
      assert has_element?(lv, "h3", "Flexible")
      assert has_element?(lv, "h3", "Enterprise")

      assert has_element?(lv, "#plan-free p", "Current plan")
      refute has_element?(lv, "#plan-flexible p", "Current plan")
      refute has_element?(lv, "#plan-enterprise p", "Current plan")

      assert has_element?(lv, "#plan-free a", "Current plan")
      assert has_element?(lv, "#plan-flexible a", "Upgrade")
      assert has_element?(lv, "#plan-enterprise a", "Contact us")
    end

    test "displays all plans when school is on free plan", %{conn: conn, school: school} do
      subscription_fixture(%{school_id: school.id, plan: :free})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/billing")

      assert has_element?(lv, "h3", "Hobby")
      assert has_element?(lv, "h3", "Flexible")
      assert has_element?(lv, "h3", "Enterprise")

      assert has_element?(lv, "#plan-free p", "Current plan")
      refute has_element?(lv, "#plan-flexible p", "Current plan")
      refute has_element?(lv, "#plan-enterprise p", "Current plan")

      assert has_element?(lv, "#plan-free a", "Current plan")
      assert has_element?(lv, "#plan-flexible a", "Upgrade")
      assert has_element?(lv, "#plan-enterprise a", "Contact us")
    end

    test "displays all plans when school is on flexible plan", %{conn: conn, school: school} do
      subscription_fixture(%{school_id: school.id, plan: :flexible})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/billing")

      assert has_element?(lv, "h3", "Hobby")
      assert has_element?(lv, "h3", "Flexible")
      assert has_element?(lv, "h3", "Enterprise")

      refute has_element?(lv, "#plan-free p", "Current plan")
      assert has_element?(lv, "#plan-flexible p", "Current plan")
      refute has_element?(lv, "#plan-enterprise p", "Current plan")

      assert has_element?(lv, "#plan-free a", "Downgrade")
      assert has_element?(lv, "#plan-flexible a", "Current plan")
      assert has_element?(lv, "#plan-enterprise a", "Contact us")
    end

    test "hides flexible plan when school is on enterprise plan", %{conn: conn, school: school} do
      subscription_fixture(%{school_id: school.id, plan: :enterprise})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/billing")

      assert has_element?(lv, "h3", "Hobby")
      refute has_element?(lv, "h3", "Flexible")
      assert has_element?(lv, "h3", "Enterprise")

      refute has_element?(lv, "#plan-free p", "Current plan")
      refute has_element?(lv, "#plan-flexible p", "Current plan")
      assert has_element?(lv, "#plan-enterprise p", "Current plan")

      assert has_element?(lv, "#plan-free a", "Downgrade")
      assert has_element?(lv, "#plan-enterprise a", "Current plan")
    end

    test "displays the correct prices", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard/billing")

      assert has_element?(lv, "#plan-free span", "Free")
      assert has_element?(lv, "#plan-flexible span", "$10")
      assert has_element?(lv, "#plan-enterprise span", "Contact us")

      refute has_element?(lv, "#plan-free span", "/month per user")
      assert has_element?(lv, "#plan-flexible span", "/month per user")
      refute has_element?(lv, "#plan-enterprise span", "/month per user")
    end
  end
end
