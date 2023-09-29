defmodule UneebeeWeb.DashboardCourseTeacherListLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Content
  import Uneebee.Fixtures.Organizations

  describe "teacher list (non-authenticated users)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn, school: school} do
      course = course_fixture(%{school_id: school.id})
      result = get(conn, ~p"/dashboard/c/#{course.slug}/teachers")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "teacher list (manager)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :manager, course_user: nil)
    end

    test "lists teachers", %{conn: conn, school: school, course: course} do
      assert_user_list(conn, school, course)
    end
  end

  describe "teacher list (school teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :teacher, course_user: nil)
    end

    test "returns 403", %{conn: conn, course: course} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/teachers") end)
    end
  end

  describe "teacher list (school student)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :student, course_user: nil)
    end

    test "returns 403", %{conn: conn, course: course} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/teachers") end)
    end
  end

  describe "teacher list (course teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, course_user: :teacher)
    end

    test "lists teachers", %{conn: conn, school: school, course: course} do
      assert_user_list(conn, school, course)
    end
  end

  describe "teacher list (course student)" do
    setup :course_setup

    test "returns 403", %{conn: conn, course: course} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/teachers") end)
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  defp assert_user_list(conn, school, course) do
    user1 = user_fixture(%{first_name: "User 1"})
    user2 = user_fixture(%{first_name: "User 2"})
    user3 = user_fixture(%{first_name: "User 3"})
    user4 = user_fixture(%{first_name: "User 4"})

    school_user_fixture(%{school: school, user: user1, role: :teacher})
    cu2 = course_user_fixture(%{course: course, user: user2, role: :teacher})
    cu3 = course_user_fixture(%{course: course, user: user3, role: :teacher, approved?: false})
    course_user_fixture(%{course: course, user: user4, role: :student})

    {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/teachers")

    assert has_element?(lv, ~s|li[aria-current="page"] span:fl-icontains("teachers")|)

    assert has_element?(lv, ~s|dt span:fl-icontains("#{user2.first_name}")|)
    assert has_element?(lv, ~s|dt span:fl-icontains("#{user3.first_name}")|)
    refute has_element?(lv, ~s|dt span:fl-icontains("#{user1.first_name}")|)
    refute has_element?(lv, ~s|dt span:fl-icontains("#{user4.first_name}")|)

    refute has_element?(lv, ~s|a:fl-icontains("stats")|)

    assert has_element?(lv, ~s|#users-#{cu3.id} span[role="status"]:fl-icontains("pending")|)
    refute has_element?(lv, ~s|#users-#{cu2.id} span[role="status"]:fl-icontains("pending")|)
  end
end
