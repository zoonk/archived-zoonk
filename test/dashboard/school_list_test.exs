defmodule UneebeeWeb.DashboardSchoolListTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Organizations

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

  describe "/dashboard/schools (managers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :manager)
    end

    test "lists schools", %{conn: conn, school: school} do
      schools = Enum.map(1..3, fn idx -> school_fixture(%{school_id: school.id, public?: idx == 1, name: "School #{idx}!"}) end)

      {:ok, lv, _html} = live(conn, "/dashboard/schools")

      Enum.each(schools, fn school ->
        status = if school.public?, do: "Public", else: "Private"

        assert has_element?(lv, "h3", school.name)
        assert has_element?(lv, "#school-#{school.id} span", status)
      end)
    end
  end
end
