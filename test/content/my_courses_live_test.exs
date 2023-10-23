defmodule UneebeeWeb.MyCoursesLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Content

  describe "my courses (non-authenticated users)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn} do
      result = get(conn, ~p"/courses/my")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "my courses (authenticated)" do
    setup :app_setup

    test "lists all courses from the current user", %{conn: conn, user: user} do
      courses = Enum.map(1..3, fn idx -> course_fixture(%{name: "Course #{idx}!"}) end)
      Enum.each(courses, fn course -> course_user_fixture(%{course: course, user: user}) end)
      other_course = course_fixture(%{name: "Other course!"})

      {:ok, lv, _html} = live(conn, ~p"/courses/my")

      assert has_element?(lv, ~s|li[aria-current=page] span:fl-icontains("my courses")|)

      Enum.each(courses, fn course -> assert has_element?(lv, ~s|a[href="/c/#{course.slug}"]|) end)
      refute has_element?(lv, ~s|a[href="/c/#{other_course.slug}"]|)
    end
  end
end
