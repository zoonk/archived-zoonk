defmodule ZoonkWeb.DashboardCourseListLiveTest do
  use ZoonkWeb.ConnCase, async: true

  import Zoonk.Fixtures.Content

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

    test "redirects to the last course this teacher edited", %{conn: conn, school: school, user: user} do
      course = course_fixture(%{school_id: school.id})
      course_fixture(%{school_id: school.id})
      course_user_fixture(%{course: course, user: user, role: :teacher})

      result = get(conn, ~p"/dashboard/courses")
      assert redirected_to(result) == ~p"/dashboard/c/#{course.slug}"
    end
  end

  describe "/dashboard/courses (managers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :manager)
    end

    test "redirects to the last course edited for this school", %{conn: conn, school: school} do
      course1 = course_fixture(%{school_id: school.id})
      course_fixture(%{school_id: school.id})
      course_fixture()
      lesson_fixture(%{course: course1})

      result = get(conn, ~p"/dashboard/courses")
      assert redirected_to(result) == ~p"/dashboard/c/#{course1.slug}"
    end

    test "redirects to the create new course page when there are no courses", %{conn: conn} do
      result = get(conn, ~p"/dashboard/courses")
      assert redirected_to(result) == ~p"/dashboard/courses/new"
    end
  end
end
