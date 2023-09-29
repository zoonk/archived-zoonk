defmodule UneebeeWeb.DashboardLessonDeleteLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Content

  alias Uneebee.Content

  describe "lesson delete (non-authenticated user)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn, school: school} do
      course = course_fixture(%{school_id: school.id})
      lesson = lesson_fixture(%{course_id: course.id})
      result = get(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/delete")
      assert redirected_to(result) == "/users/login"
    end
  end

  describe "lesson delete (school teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :teacher, course_user: nil)
    end

    test "returns 403", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/delete") end)
    end
  end

  describe "lesson delete (student)" do
    setup :course_setup

    test "returns 403", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/delete") end)
    end
  end

  describe "lesson delete (course teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :teacher, course_user: :teacher)
    end

    test "deletes a lesson", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/delete")

      assert has_element?(lv, ~s|li[aria-current=page] span:fl-icontains("delete lesson")|)

      lv |> form("#delete-form", %{confirmation: "CONFIRM"}) |> render_submit()

      assert_raise Ecto.NoResultsError, fn -> Content.get_lesson!(lesson.id) end
    end

    test "doesn't delete if confirmation message doesn't match", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/delete")

      assert has_element?(lv, ~s|li[aria-current="page"] span:fl-icontains("delete lesson")|)

      result =
        lv
        |> form("#delete-form", %{confirmation: "WRONG"})
        |> render_submit()

      assert result =~ "Confirmation message does not match."

      assert Content.get_lesson!(lesson.id).name == lesson.name
    end
  end
end
