defmodule UneebeeWeb.LessonCompletedLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Content

  alias Uneebee.Content

  describe "completed view (non-authenticated user)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn, school: school} do
      course = course_fixture(%{school_id: school.id})
      lesson = lesson_fixture(%{course_id: course.id})

      result = get(conn, ~p"/c/#{course.slug}/#{lesson.id}/completed")
      assert redirected_to(result) == "/users/login"
    end
  end

  describe "completed view (pending course user)" do
    setup do
      course_setup(%{conn: build_conn()}, course_user: :pending)
    end

    test "returns 403", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})

      assert_error_sent 403, fn ->
        get(conn, ~p"/c/#{course.slug}/#{lesson.id}/completed")
      end
    end
  end

  describe "completed view (course user)" do
    setup :course_setup

    test "displays the lesson results", %{conn: conn, course: course, user: user} do
      lesson = lesson_fixture(%{course_id: course.id})
      Content.add_user_lesson(%{user_id: user.id, lesson_id: lesson.id, attempts: 1, correct: 7, total: 10})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}/completed")

      assert has_element?(lv, ~s|h1:fl-icontains("Good!")|)
      assert has_element?(lv, ~s|img[src="/images/lessons/good.svg"]|)
      assert has_element?(lv, ~s|p:fl-icontains("You got 7 out of 10 answers right.")|)
      assert has_element?(lv, ~s|div:fl-icontains("7.0")|)
      assert has_element?(lv, ~s|a[href="/c/#{course.slug}"]:fl-icontains("back to the course")|)
    end
  end
end
