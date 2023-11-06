defmodule UneebeeWeb.CourseViewLiveTest do
  @moduledoc false
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Content

  alias Uneebee.Content

  describe "/c/:slug (non-authenticated)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn, school: school} do
      course = course_fixture(%{school_id: school.id})
      result = get(conn, ~p"/c/#{course.slug}")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "/c/:slug (private course, non school user)" do
    setup do
      course_setup(%{conn: build_conn()}, public_course?: false, school_user: nil, course_user: nil)
    end

    test "can ask to enroll", %{conn: conn, course: course} do
      lesson_fixture(%{course_id: course.id, name: "Lesson 1", published?: true})
      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}")
      assert has_element?(lv, ~s|span:fl-icontains("locked")|)

      result = lv |> element("button", "Request to join") |> render_click()

      assert result =~ "A request to enroll has been sent to the course teacher."
      refute has_element?(lv, ~s|button:fl-icontains("request to join")|)
      assert has_element?(lv, ~s|span:fl-icontains("pending approval")|)
      assert has_element?(lv, ~s|span:fl-icontains("locked")|)
    end
  end

  describe "/c/:slug (public course, non course user)" do
    setup do
      course_setup(%{conn: build_conn()}, course_user: nil)
    end

    test "allows to automatically enroll", %{conn: conn, course: course} do
      lesson_fixture(%{course_id: course.id, name: "Lesson 1", published?: true})
      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}")
      refute has_element?(lv, ~s|span:fl-icontains("locked")|)
      refute has_element?(lv, ~s|button[phx-click="enroll"]|)
    end
  end

  describe "/c/:slug (manager)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :manager, course_user: nil)
    end

    test "renders the page", %{conn: conn, course: course} do
      assert_course_view(conn, course)
    end
  end

  describe "/c/:slug (school teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :teacher, course_user: nil)
    end

    test "renders the page", %{conn: conn, course: course} do
      assert_course_view(conn, course)
    end
  end

  describe "/c/:slug (course teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, course_user: :teacher)
    end

    test "renders the page", %{conn: conn, course: course} do
      assert_course_view(conn, course)
    end
  end

  describe "/c/:slug (course student)" do
    setup :course_setup

    test "lists only published lessons", %{conn: conn, course: course} do
      lesson1 = lesson_fixture(%{course_id: course.id, name: "Lesson 1", published?: true})
      lesson2 = lesson_fixture(%{course_id: course.id, name: "Lesson 2", published?: false})

      {:ok, lv, _html} = live(conn, "/c/#{course.slug}")

      assert has_element?(lv, ~s|dt *:fl-contains("#{lesson1.name}")|)
      refute has_element?(lv, ~s|dt *:fl-contains("#{lesson2.name}")|)
    end

    test "displays the course progress", %{conn: conn, course: course, user: user, lesson: lesson} do
      Enum.each(1..3, fn _idx -> lesson_fixture(%{course_id: course.id, published?: true}) end)
      Content.add_user_lesson(%{user_id: user.id, lesson_id: lesson.id, attempts: 1, correct: 3, total: 4})

      {:ok, lv, _html} = live(conn, "/c/#{course.slug}")

      assert has_element?(lv, ~s|span:fl-contains("25%")|)
    end
  end

  defp assert_course_view(conn, course) do
    {:ok, lv, _html} = live(conn, "/c/#{course.slug}")
    assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("home")|)
    assert has_element?(lv, ~s|h1:fl-icontains("#{course.name}")|)
  end
end
