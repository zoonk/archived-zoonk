defmodule UneebeeWeb.DashboardHomeLiveTest do
  @moduledoc false
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "/dashboard (non-authenticated users)" do
    setup :set_school

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
      assert_dashboard(conn, school)
    end
  end

  defp assert_dashboard(conn, school) do
    {:ok, lv, _html} = live(conn, ~p"/dashboard")
    assert has_element?(lv, ~s|h1:fl-icontains("#{school.name}")|)
    assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("manage school")|)
  end
end
