defmodule UneebeeWeb.DashboardLessonCoverLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Content
  import UneebeeWeb.TestHelpers.Upload

  alias Uneebee.Content

  describe "lesson cover (non-authenticated user)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn, school: school} do
      course = course_fixture(%{school_id: school.id})
      lesson = lesson_fixture(%{course_id: course.id})
      result = get(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/cover")
      assert redirected_to(result) == "/users/login"
    end
  end

  describe "lesson cover (school teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :teacher, course_user: nil)
    end

    test "returns 403", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/cover") end)
    end
  end

  describe "lesson cover (student)" do
    setup :course_setup

    test "returns 403", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/cover") end)
    end
  end

  describe "lesson cover (school manager)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :manager, course_user: nil)
    end

    test "updates the cover image", %{conn: conn, course: course} do
      assert_cover_upload(conn, course)
    end
  end

  describe "lesson cover (course teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :teacher, course_user: :teacher)
    end

    test "updates the cover image", %{conn: conn, course: course} do
      assert_cover_upload(conn, course)
    end
  end

  defp assert_cover_upload(conn, course) do
    lesson = lesson_fixture(%{course_id: course.id})
    {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/cover")

    assert has_element?(lv, ~s|li[aria-current=page] span:fl-icontains("cover")|)
    assert_file_upload(lv, "lesson_cover")

    updated_lesson = Content.get_lesson!(lesson.id)
    assert String.starts_with?(updated_lesson.cover, "/uploads")
  end
end
