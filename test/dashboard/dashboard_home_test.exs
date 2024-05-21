defmodule ZoonkWeb.DashboardHomeLiveTest do
  @moduledoc false
  use ZoonkWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Zoonk.Fixtures.Organizations

  describe "/dashboard (non-authenticated users)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn} do
      result = get(conn, "/dashboard")
      assert redirected_to(result) == "/users/login"
    end
  end

  describe "/dashboard (allow guests)" do
    setup do
      set_school(%{conn: build_conn()}, allow_guests?: true)
    end

    test "redirects to the login page", %{conn: conn} do
      result = get(conn, "/dashboard")
      assert redirected_to(result) == "/users/login"
    end
  end

  describe "/dashboard (teachers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :teacher)
    end

    test "returns 403", %{conn: conn} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard") end)
    end
  end

  describe "/dashboard (managers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :manager)
    end

    test "renders the page", %{conn: conn, school: school} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard")
      assert_dashboard(lv, school, school.custom_domain)
    end

    test "displays the data for a child school", %{conn: conn, school: school, user: user} do
      child_school = school_fixture(%{school_id: school.id})
      school_user_fixture(%{user: user, school: child_school, role: :manager})
      host = "#{child_school.slug}.#{school.custom_domain}"
      conn = Map.put(conn, :host, host)

      {:ok, lv, _html} = live(conn, ~p"/dashboard")

      assert_dashboard(lv, child_school, host)
    end
  end

  describe "/dashboard (saas)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :manager, school_kind: :saas)
    end

    test "renders the schools menu", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard")
      assert has_element?(lv, schools_el())
    end
  end

  describe "/dashboard (marketplace)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :manager, school_kind: :marketplace)
    end

    test "renders the schools menu", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard")
      assert has_element?(lv, schools_el())
    end
  end

  describe "/dashboard (white label)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :manager, school_kind: :white_label)
    end

    test "renders the schools menu", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard")
      refute has_element?(lv, schools_el())
    end

    test "hides billing menu if the application doesn't support Stripe", %{conn: conn} do
      Application.put_env(:stripity_stripe, :api_key, nil)

      assert {:ok, lv, _html} = live(conn, ~p"/dashboard")
      refute has_element?(lv, "li", "Billing")

      Application.put_env(:stripity_stripe, :api_key, "sk_test_thisisaboguskey")
    end
  end

  defp assert_dashboard(lv, school, host) do
    assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("manage school")|)
    assert has_element?(lv, ~s|h1 *:fl-icontains("#{school.name}")|)
    assert has_element?(lv, ~s|h1 *:fl-icontains("@#{school.slug}")|)
    assert has_element?(lv, ~s|header p:fl-icontains("#{host}")|)
  end

  defp schools_el, do: ~s|a[href="/dashboard/schools"]:fl-icontains("schools")|
end
