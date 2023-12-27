defmodule UneebeeWeb.DashboardSchoolViewTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Organizations

  describe "/dashboard/schools/:id (non-authenticated users)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn, school: school} do
      child_school = school_fixture(%{school_id: school.id})
      result = get(conn, "/dashboard/schools/#{child_school.id}")
      assert redirected_to(result) == "/users/login"
    end
  end

  describe "/dashboard/schools/:id (teachers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :teacher)
    end

    test "returns 403", %{conn: conn, school: school} do
      child_school = school_fixture(%{school_id: school.id})
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/schools/#{child_school.id}") end)
    end
  end

  describe "/dashboard/schools/:id (managers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :manager, school_kind: :saas)
    end

    test "displays school", %{conn: conn, school: school} do
      child_school = school_fixture(%{school_id: school.id, custom_domain: "example.com"})
      Enum.each(1..6, fn _idx -> school_user_fixture(%{school: child_school}) end)

      {:ok, lv, _html} = live(conn, "/dashboard/schools/#{child_school.id}")

      refute has_element?(lv, "li", "Billing")
      assert has_element?(lv, "h1", child_school.name)
      assert has_element?(lv, "h1", child_school.slug)
      assert has_element?(lv, "p", child_school.custom_domain)
      assert has_element?(lv, "span", "6")
    end
  end
end
