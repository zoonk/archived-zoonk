defmodule ZoonkWeb.DashboardCourseViewLiveTest do
  use ZoonkWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Zoonk.Fixtures.Accounts
  import Zoonk.Fixtures.Content

  alias Zoonk.Content

  @select_form "#select-course"

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

    test "switches to a different course", %{conn: conn, school: school, course: course} do
      course2 = course_fixture(%{school_id: school.id})
      lesson_fixture(%{course: course2})

      {:ok, lv, _html} = live(conn, "/dashboard/c/#{course.slug}")

      assert has_element?(lv, "option[selected]", course.name)

      {:ok, updated_lv, _html} =
        lv
        |> form(@select_form, course: course2.slug)
        |> render_change()
        |> follow_redirect(conn, ~p"/dashboard/c/#{course2.slug}")

      assert has_element?(updated_lv, "option[selected]", course2.name)
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

      refute has_element?(lv, "dt", "Lesson 2")

      {:ok, updated_lv, _html} =
        lv
        |> element("button", "+ Lesson")
        |> render_click()
        |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}")

      assert has_element?(updated_lv, "dt", "Lesson 2")
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

    test "switches to a different course", %{conn: conn, school: school, course: course, user: user} do
      course2 = course_fixture(%{school_id: school.id})
      course3 = course_fixture(%{school_id: school.id})
      course_user_fixture(%{course: course2, user: user, role: :teacher})
      lesson_fixture(%{course: course2})
      lesson_fixture(%{course: course3})

      {:ok, lv, _html} = live(conn, "/dashboard/c/#{course.slug}")

      assert has_element?(lv, "option[selected]", course.name)
      assert has_element?(lv, "option", course2.name)
      refute has_element?(lv, "option", course3.name)

      {:ok, updated_lv, _html} =
        lv
        |> form(@select_form, course: course2.slug)
        |> render_change()
        |> follow_redirect(conn, ~p"/dashboard/c/#{course2.slug}")

      assert has_element?(updated_lv, "option[selected]", course2.name)
    end

    test "switches to the create new course page", %{conn: conn, course: course} do
      {:ok, lv, _html} = live(conn, "/dashboard/c/#{course.slug}")

      {:ok, updated_lv, _html} =
        lv
        |> form(@select_form, course: "new-course")
        |> render_change()
        |> follow_redirect(conn, ~p"/dashboard/courses/new")

      assert has_element?(updated_lv, "h1", "Create course")
    end

    test "reorder lessons", %{conn: conn, course: course} do
      lessons = Enum.map(1..3, fn idx -> lesson_fixture(%{course_id: course.id, name: "lesson#{idx}"}) end)

      {:ok, lv, html} = live(conn, "/dashboard/c/#{course.slug}")

      Enum.each(lessons, fn lesson -> assert has_element?(lv, "dt", lesson.name) end)
      assert get_lesson_titles(html) == ["lesson1", "lesson2", "lesson3"]

      updated_html = render_hook(lv, :reposition, %{"new" => 1, "old" => 3})
      assert get_lesson_titles(updated_html) == ["lesson3", "lesson1", "lesson2"]
    end
  end

  defp assert_course_view(conn, course) do
    lessons = Enum.map(1..3, fn idx -> lesson_fixture(%{course_id: course.id, name: "Lesson #{idx}!"}) end)
    users = Enum.map(1..3, fn _idx -> user_fixture() end)
    Enum.each(users, fn user -> generate_user_lesson(user.id, 0, lessons: lessons) end)

    {:ok, lv, _html} = live(conn, "/dashboard/c/#{course.slug}")

    assert has_element?(lv, "option[selected]", course.name)
    assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("overview")|)

    Enum.each(lessons, fn lesson ->
      assert has_element?(lv, "dt", lesson.name)
      assert has_element?(lv, ~s|#lesson-#{lesson.id} span:fl-contains("3")|)
    end)
  end

  # Get the title of each created lesson on the right order.
  # This is useful when testing if the reordering of lessons is working.
  defp get_lesson_titles(html) do
    html
    |> Floki.parse_document!()
    |> Floki.find("#lesson-list a dt")
    |> Enum.map(&Floki.text/1)
    # We don't want the first element because it's created dynamically, so it's hard to test it
    |> tl()
  end
end
