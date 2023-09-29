defmodule UneebeeWeb.DashboardLessonEditLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Content

  alias Uneebee.Content

  @lesson_form "#lesson-form"

  describe "lesson edit info (non-authenticated user)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn, school: school} do
      course = course_fixture(%{school_id: school.id})
      lesson = lesson_fixture(%{course_id: course.id})
      result = get(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/info")
      assert redirected_to(result) == "/users/login"
    end
  end

  describe "lesson edit info (manager)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :manager, course_user: nil)
    end

    test "updates the form", %{conn: conn, course: course} do
      assert_info_form(conn, course)
    end
  end

  describe "lesson edit info (school teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :teacher, course_user: nil)
    end

    test "returns 403", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/info") end)
    end
  end

  describe "lesson edit info (student)" do
    setup :course_setup

    test "returns 403", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/info") end)
    end
  end

  describe "lesson edit info (course teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :teacher, course_user: :teacher)
    end

    test "updates the form", %{conn: conn, course: course} do
      assert_info_form(conn, course)
    end
  end

  defp assert_info_form(conn, course) do
    lesson = lesson_fixture(%{course_id: course.id})
    {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/info")

    assert has_element?(lv, ~s|li[aria-current=page] span:fl-icontains("Information")|)

    assert_lesson_name(lv)
    assert_lesson_description(lv)

    attrs = %{name: "New lesson name", description: "New lesson description"}
    result = lv |> form(@lesson_form, lesson: attrs) |> render_submit()
    assert result =~ "Lesson updated successfully!"

    updated_lesson = Content.get_lesson!(lesson.id)
    assert updated_lesson.name == attrs.name
    assert updated_lesson.description == attrs.description
  end

  defp assert_lesson_name(lv) do
    lv |> element(@lesson_form) |> render_change(lesson: %{name: ""})
    assert has_element?(lv, ~s|div[phx-feedback-for="lesson[name]"] p:fl-icontains("can't be blank")|)
  end

  defp assert_lesson_description(lv) do
    lv |> element(@lesson_form) |> render_change(lesson: %{description: ""})
    assert has_element?(lv, ~s|div[phx-feedback-for="lesson[description]"] p:fl-icontains("can't be blank")|)
  end
end
