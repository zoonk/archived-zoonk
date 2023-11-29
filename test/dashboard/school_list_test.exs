defmodule UneebeeWeb.DashboardSchoolListTest do
  use UneebeeWeb.ConnCase, async: true

  describe "/dashboard/schools (non-authenticated users)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn} do
      result = get(conn, "/dashboard/schools")
      assert redirected_to(result) == "/users/login"
    end
  end

  describe "/dashboard/schools (teachers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :teacher)
    end

    test "returns 403", %{conn: conn} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/schools") end)
    end
  end
end
