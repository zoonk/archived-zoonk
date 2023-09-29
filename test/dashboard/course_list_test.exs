defmodule UneebeeWeb.DashboardCourseListLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Content

  describe "/dashboard/courses (non-authenticated users)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn} do
      result = get(conn, ~p"/dashboard/courses")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "/dashboard/courses (students)" do
    setup :app_setup

    test "returns a 403 error", %{conn: conn} do
      assert_error_sent 403, fn -> get(conn, ~p"/dashboard/courses") end
    end
  end

  describe "/dashboard/courses (teachers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :teacher)
    end

    test "returns all courses a teacher manages", %{conn: conn, school: school, user: user} do
      courses = Enum.map(1..3, fn _idx -> course_fixture(%{school_id: school.id, user: user, preload: :school}) end)
      other_courses = Enum.map(1..3, fn _idx -> course_fixture(%{school_id: school.id, preload: :school}) end)

      {:ok, lv, _html} = live(conn, ~p"/dashboard/courses")

      Enum.each(courses, fn course -> assert has_element?(lv, course_el(course)) end)
      Enum.each(other_courses, fn course -> refute has_element?(lv, course_el(course)) end)
    end
  end

  describe "/dashboard/courses (managers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :manager)
    end

    test "returns all courses from a school", %{conn: conn, school: school} do
      courses = Enum.map(1..3, fn _idx -> course_fixture(%{school_id: school.id, preload: :school}) end)

      {:ok, lv, _html} = live(conn, ~p"/dashboard/courses")

      Enum.each(courses, fn course -> assert has_element?(lv, course_el(course)) end)
    end
  end

  defp course_el(course), do: ~s|#course-list a[href="/dashboard/c/#{course.slug}"]|
end
