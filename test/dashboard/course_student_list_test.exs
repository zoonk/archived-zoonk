defmodule UneebeeWeb.DashboardCourseStudentListLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Content
  import Uneebee.Fixtures.Organizations

  describe "student list (non-authenticated users)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn, school: school} do
      course = course_fixture(%{school_id: school.id})
      result = get(conn, ~p"/dashboard/c/#{course.slug}/students")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "student list (manager)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :manager, course_user: nil)
    end

    test "lists students", %{conn: conn, school: school, course: course} do
      assert_user_list(conn, school, course)
    end

    test "approves a pending user", %{conn: conn, course: course} do
      assert_approve_or_reject_user(conn, course, :approve)
    end

    test "rejects a pending user", %{conn: conn, course: course} do
      assert_approve_or_reject_user(conn, course, :reject)
    end

    test "removes a user", %{conn: conn, course: course} do
      assert_remove_user(conn, course)
    end
  end

  describe "student list (school teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :teacher, course_user: nil)
    end

    test "returns 403", %{conn: conn, course: course} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/students") end)
    end
  end

  describe "student list (school student)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :student, course_user: nil)
    end

    test "returns 403", %{conn: conn, course: course} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/students") end)
    end
  end

  describe "student list (course teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, course_user: :teacher)
    end

    test "lists students", %{conn: conn, school: school, course: course} do
      assert_user_list(conn, school, course)
    end

    test "approves a pending user", %{conn: conn, course: course} do
      assert_approve_or_reject_user(conn, course, :approve)
    end

    test "rejects a pending user", %{conn: conn, course: course} do
      assert_approve_or_reject_user(conn, course, :reject)
    end

    test "removes a user", %{conn: conn, course: course} do
      assert_remove_user(conn, course)
    end

    test "adds a user using their email address", %{conn: conn, course: course} do
      user = user_fixture(%{first_name: "Leo", last_name: "Da Vinci"})
      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/students")

      refute has_element?(lv, ~s|dt span:fl-icontains("Leo da Vinci")|)

      {:ok, updated_lv, html} =
        lv
        |> form("#add-user-form", %{email_or_username: user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}/students")

      assert html =~ "User added!"
      assert has_element?(updated_lv, ~s|dt span:fl-icontains("#{user.first_name}")|)
    end

    test "adds a user using their username", %{conn: conn, course: course} do
      user = user_fixture(%{first_name: "Leo", last_name: "Da Vinci"})
      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/students")

      refute has_element?(lv, ~s|dt span:fl-icontains("Leo da Vinci")|)

      {:ok, updated_lv, html} =
        lv
        |> form("#add-user-form", %{email_or_username: user.username})
        |> render_submit()
        |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}/students")

      assert html =~ "User added!"
      assert has_element?(updated_lv, ~s|dt span:fl-icontains("#{user.first_name}")|)
    end

    test "displays an error when trying to add an unexisting user", %{conn: conn, course: course} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/students")

      result =
        lv
        |> form("#add-user-form", %{email_or_username: "unexisting"})
        |> render_submit()

      assert result =~ "User not found!"
    end
  end

  describe "student list (course student)" do
    setup :course_setup

    test "returns 403", %{conn: conn, course: course} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/students") end)
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  defp assert_user_list(conn, school, course) do
    user1 = user_fixture(%{first_name: "User 1"})
    user2 = user_fixture(%{first_name: "User 2"})
    user3 = user_fixture(%{first_name: "User 3"})
    user4 = user_fixture(%{first_name: "User 4"})

    school_user_fixture(%{school: school, user: user1, role: :student})
    cu2 = course_user_fixture(%{course: course, user: user2, role: :student})
    cu3 = course_user_fixture(%{course: course, user: user3, role: :student, approved?: false})
    course_user_fixture(%{course: course, user: user4, role: :teacher})

    {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/students")

    assert has_element?(lv, ~s|li[aria-current="page"] span:fl-icontains("students")|)

    assert has_element?(lv, ~s|a:fl-icontains("details")|)

    assert has_element?(lv, ~s|dt span:fl-icontains("#{user2.first_name}")|)
    assert has_element?(lv, ~s|dt span:fl-icontains("#{user3.first_name}")|)
    refute has_element?(lv, ~s|dt span:fl-icontains("#{user1.first_name}")|)
    refute has_element?(lv, ~s|dt span:fl-icontains("#{user4.first_name}")|)

    assert has_element?(lv, ~s|#users-#{cu3.id} span[role="status"]:fl-icontains("pending")|)
    refute has_element?(lv, ~s|#users-#{cu2.id} span[role="status"]:fl-icontains("pending")|)
  end

  defp assert_approve_or_reject_user(conn, course, action) do
    pending_user = user_fixture(%{first_name: "Pending User"})
    cu = course_user_fixture(%{course: course, user: pending_user, role: :student, approved?: false})
    pending_el = ~s|#users-#{cu.id} span[role="status"]:fl-icontains("pending")|

    {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/students")

    assert has_element?(lv, pending_el)

    {:ok, updated_lv, html} =
      lv
      |> element(get_approve_el(action))
      |> render_click()
      |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}/students")

    assert html =~ get_confirmation_message(action)
    refute has_element?(updated_lv, pending_el)
  end

  defp assert_remove_user(conn, course) do
    user = user_fixture(%{first_name: "Leo", last_name: "Da Vinci"})
    course_user_fixture(%{course: course, user: user, role: :student})
    user_el = ~s|dt span:fl-icontains("Leo da Vinci")|

    {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/students")

    assert has_element?(lv, user_el)

    {:ok, updated_lv, html} =
      lv
      |> element(~s|button[phx-click="remove"]|)
      |> render_click()
      |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}/students")

    assert html =~ "User removed!"
    refute has_element?(updated_lv, user_el)
  end

  defp get_approve_el(:approve), do: ~s|button[phx-click="approve"]|
  defp get_approve_el(:reject), do: ~s|button[phx-click="reject"]|

  defp get_confirmation_message(:approve), do: "User approved!"
  defp get_confirmation_message(:reject), do: "User rejected!"
end
