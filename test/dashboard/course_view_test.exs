defmodule UneebeeWeb.DashboardCourseViewLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Content

  alias Uneebee.Content

  describe "/dashboard/c/:slug (non-authenticated users)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn} do
      result = get(conn, ~p"/dashboard/c/some-course")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "/dashboard/c/:slug (students)" do
    setup :course_setup

    test "returns a 403 error", %{conn: conn, course: course} do
      assert_error_sent 403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}") end
    end
  end

  describe "/dashboard/c/:slug (school teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :teacher)
    end

    test "returns 403", %{conn: conn, course: course} do
      assert_error_sent 403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}") end
    end
  end

  describe "/dashboard/c/:slug (manager)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :manager)
    end

    test "renders the page", %{conn: conn, course: course} do
      assert_course_view(conn, course)
    end
  end

  describe "/dashboard/c/:slug (course teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, course_user: :teacher)
    end

    test "renders the page", %{conn: conn, course: course} do
      assert_course_view(conn, course)
    end

    test "creates a lesson", %{conn: conn, course: course} do
      {:ok, lv, _html} = live(conn, "/dashboard/c/#{course.slug}")

      refute has_element?(lv, "dt", "Lesson 1")

      {:ok, updated_lv, _html} =
        lv
        |> element("button", "+ Lesson")
        |> render_click()
        |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}")

      assert has_element?(updated_lv, "dt", "Lesson 1")
    end

    test "publishes a course", %{conn: conn, course: course} do
      Content.update_course(course, %{published?: false})

      {:ok, lv, _html} = live(conn, "/dashboard/c/#{course.slug}")

      assert lv |> element("button", "Publish") |> render_click() =~ "Unpublish"

      updated_course = Content.get_course!(course.id)
      assert updated_course.published?
    end

    test "unpublishes a course", %{conn: conn, course: course} do
      Content.update_course(course, %{published?: true})

      {:ok, lv, _html} = live(conn, "/dashboard/c/#{course.slug}")

      assert lv |> element("button", "Unpublish") |> render_click() =~ "Publish"

      updated_course = Content.get_course!(course.id)
      refute updated_course.published?
    end
  end

  defp assert_course_view(conn, course) do
    lessons = Enum.map(1..3, fn idx -> lesson_fixture(%{course_id: course.id, name: "Lesson #{idx}!"}) end)

    {:ok, lv, _html} = live(conn, "/dashboard/c/#{course.slug}")

    assert has_element?(lv, "h1", course.name)
    assert has_element?(lv, ~s|li[aria-current=page] span:fl-icontains("course page")|)

    Enum.each(lessons, fn lesson -> assert has_element?(lv, "dt", lesson.name) end)
  end
end
