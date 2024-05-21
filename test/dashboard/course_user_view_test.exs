defmodule ZoonkWeb.DashboardCourseStudentViewLiveTest do
  use ZoonkWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Zoonk.Fixtures.Accounts
  import Zoonk.Fixtures.Content

  alias Zoonk.Content

  describe "user view (non-authenticated users)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn, school: school} do
      course = course_fixture(%{school_id: school.id})
      result = get(conn, ~p"/dashboard/c/#{course.slug}/u/1")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "user view (school teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :teacher, course_user: nil)
    end

    test "returns 403", %{conn: conn, course: course} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/u/1") end)
    end
  end

  describe "user view (school student)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :student, course_user: nil)
    end

    test "returns 403", %{conn: conn, course: course} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/u/1") end)
    end
  end

  describe "user view (school manager)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :manager, course_user: nil)
    end

    test "renders the page", %{conn: conn, course: course} do
      assert_page_render(conn, course)
    end

    test "returns 403 when the user is not a course user", %{conn: conn, course: course} do
      user = user_fixture()
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/u/#{user.id}") end)
    end
  end

  describe "user view (course teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: nil, course_user: :teacher)
    end

    test "renders the page", %{conn: conn, course: course} do
      assert_page_render(conn, course)
    end

    test "approves a pending user", %{conn: conn, course: course} do
      pending_user = user_fixture(%{first_name: "Pending User"})
      course_user_fixture(%{course: course, user: pending_user, role: :student, approved?: false})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/u/#{pending_user.id}")

      refute has_element?(lv, ~s|button *:fl-icontains("remove")|)
      assert lv |> element("button", "Approve") |> render_click() =~ "User approved!"
      assert has_element?(lv, ~s|button *:fl-icontains("remove")|)
    end

    test "rejects a pending user", %{conn: conn, course: course} do
      pending_user = user_fixture(%{first_name: "Pending User"})
      course_user_fixture(%{course: course, user: pending_user, role: :student, approved?: false})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/u/#{pending_user.id}")

      refute has_element?(lv, ~s|button *:fl-icontains("remove")|)

      {:ok, _updated_lv, html} =
        lv
        |> element("button", "Reject")
        |> render_click()
        |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}/users")

      assert html =~ "User rejected!"
      refute Content.get_course_user_by_id(course.id, pending_user.id)
    end

    test "removes a user", %{conn: conn, course: course} do
      user = user_fixture(%{first_name: "Leo", last_name: "Da Vinci"})
      course_user_fixture(%{course: course, user: user, role: :student})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/u/#{user.id}")

      {:ok, _updated_lv, _html} =
        lv
        |> element("button", "Remove")
        |> render_click()
        |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}/users")

      refute Content.get_course_user_by_id(course.id, user.id)
    end

    test "hide stats for course teachers", %{conn: conn, course: course} do
      user = user_fixture()
      course_user_fixture(%{course: course, user: user, role: :teacher})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/u/#{user.id}")

      assert has_element?(lv, ~s|span:fl-icontains("teacher")|)
      refute has_element?(lv, ~s|span:fl-icontains("student")|)
      refute has_element?(lv, ~s|span:fl-icontains("course progress")|)
      refute has_element?(lv, ~s|span:fl-icontains("course score")|)
      refute has_element?(lv, ~s|article|)
    end
  end

  defp assert_page_render(conn, course) do
    user = user_fixture()
    [lesson1, lesson2] = setup_data(user, course)

    {:ok, lv, _html} = live(conn, "/dashboard/c/#{course.slug}/u/#{user.id}")

    assert has_element?(lv, ~s|h1 span:fl-contains("#{user.username}")|)
    assert has_element?(lv, ~s|h1 span:fl-contains("@#{user.username}")|)
    assert has_element?(lv, ~s|p:fl-contains("#{user.email}")|)
    assert has_element?(lv, ~s|span:fl-icontains("course progress")|)
    assert has_element?(lv, ~s|span:fl-icontains("course score")|)

    assert_lesson_render(lv)
    assert_user_selections(lv, lesson1, lesson2)
  end

  defp setup_data(user, course) do
    course_user_fixture(%{course_id: course.id, user_id: user.id})

    lesson1 = lesson_fixture(%{course_id: course.id, published?: true, name: "Lesson 1!"})
    lesson2 = lesson_fixture(%{course_id: course.id, published?: true, name: "Lesson 2!"})

    lesson_step1 = lesson_step_fixture(%{lesson_id: lesson1.id, content: "Step 1!", published?: true})
    lesson_step2 = lesson_step_fixture(%{lesson_id: lesson2.id, content: "Step 2!", published?: true})
    lesson_step3 = lesson_step_fixture(%{lesson_id: lesson1.id, content: "Step 3!", kind: :open_ended})

    option1 = step_option_fixture(%{lesson_step_id: lesson_step1.id, title: "Option 1!", correct?: true})
    option2 = step_option_fixture(%{lesson_step_id: lesson_step1.id, title: "Option 2!", correct?: false})
    option3 = step_option_fixture(%{lesson_step_id: lesson_step2.id, title: "Option 3!", correct?: true})

    Content.add_user_lesson(%{duration: 5, user_id: user.id, lesson_id: lesson1.id, attempts: 1, correct: 3, total: 10})
    Content.add_user_lesson(%{duration: 5, user_id: user.id, lesson_id: lesson2.id, attempts: 1, correct: 7, total: 10})

    Content.add_user_selection(%{duration: 5, user_id: user.id, option_id: option1.id, lesson_id: lesson1.id, step_id: lesson_step1.id})
    Content.add_user_selection(%{duration: 5, user_id: user.id, option_id: option2.id, lesson_id: lesson1.id, step_id: lesson_step1.id})
    Content.add_user_selection(%{duration: 5, user_id: user.id, option_id: option3.id, lesson_id: lesson2.id, step_id: lesson_step2.id})
    Content.add_user_selection(%{duration: 5, user_id: user.id, answer: "test answer", lesson_id: lesson1.id, step_id: lesson_step3.id})

    [lesson1, lesson2]
  end

  defp assert_lesson_render(lv) do
    assert has_element?(lv, "h3", "Lesson 1!")
    assert has_element?(lv, "h3", "Lesson 2!")
    assert has_element?(lv, "span", "3.0")
    assert has_element?(lv, "span", "7.0")
  end

  defp assert_user_selections(lv, lesson1, lesson2) do
    assert has_element?(lv, "#lessons-#{lesson1.id} p", "Option 2!")
    assert has_element?(lv, "#lessons-#{lesson1.id} p", "test answer")
    refute has_element?(lv, "#lessons-#{lesson1.id} p", "Option 1!")

    refute has_element?(lv, "#lessons-#{lesson2.id} p", "Option 3!")
    assert has_element?(lv, "#lessons-#{lesson2.id} h4", "All answers were correct.")
  end
end
