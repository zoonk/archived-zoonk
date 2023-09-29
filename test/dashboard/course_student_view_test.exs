defmodule UneebeeWeb.DashboardCourseStudentViewLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Content

  alias Uneebee.Content

  describe "student view (non-authenticated users)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn, school: school} do
      course = course_fixture(%{school_id: school.id})
      result = get(conn, ~p"/dashboard/c/#{course.slug}/s/1")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "student view (school teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :teacher, course_user: nil)
    end

    test "returns 403", %{conn: conn, course: course} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/s/1") end)
    end
  end

  describe "student view (school student)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :student, course_user: nil)
    end

    test "returns 403", %{conn: conn, course: course} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/s/1") end)
    end
  end

  describe "student view (school manager)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :manager, course_user: nil)
    end

    test "renders the page", %{conn: conn, course: course} do
      assert_page_render(conn, course)
    end
  end

  describe "student view (course teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: nil, course_user: :teacher)
    end

    test "renders the page", %{conn: conn, course: course} do
      assert_page_render(conn, course)
    end
  end

  defp assert_page_render(conn, course) do
    today = Date.utc_today()
    age = 20
    {:ok, date_of_birth} = Date.new(today.year - age, today.month, today.day)

    user = user_fixture(%{date_of_birth: date_of_birth})
    [lesson1, lesson2] = setup_data(user, course)

    {:ok, lv, _html} = live(conn, "/dashboard/c/#{course.slug}/s/#{user.username}")

    assert has_element?(lv, ~s|h1:fl-contains("#{user.first_name} #{user.last_name}, #{age}")|)
    assert has_element?(lv, ~s|h2:fl-contains("@#{user.username} - #{user.email}")|)

    assert_lesson_render(lv)
    assert_user_selections(lv, lesson1, lesson2)
  end

  defp setup_data(user, course) do
    course_user_fixture(%{course_id: course.id, user_id: user.id})

    lesson1 = lesson_fixture(%{course_id: course.id, published?: true, name: "Lesson 1!"})
    lesson2 = lesson_fixture(%{course_id: course.id, published?: true, name: "Lesson 2!"})

    lesson_step1 = lesson_step_fixture(%{lesson_id: lesson1.id, content: "Step 1!", published?: true})
    lesson_step2 = lesson_step_fixture(%{lesson_id: lesson2.id, content: "Step 2!", published?: true})

    option1 = step_option_fixture(%{lesson_step_id: lesson_step1.id, title: "Option 1!", correct?: true})
    option2 = step_option_fixture(%{lesson_step_id: lesson_step1.id, title: "Option 2!", correct?: false})
    option3 = step_option_fixture(%{lesson_step_id: lesson_step2.id, title: "Option 3!", correct?: true})

    Content.add_user_lesson(%{user_id: user.id, lesson_id: lesson1.id, attempts: 1, correct: 3, total: 10})
    Content.add_user_lesson(%{user_id: user.id, lesson_id: lesson2.id, attempts: 1, correct: 7, total: 10})

    Content.add_user_selection(%{user_id: user.id, option_id: option1.id, lesson_id: lesson1.id})
    Content.add_user_selection(%{user_id: user.id, option_id: option2.id, lesson_id: lesson1.id})
    Content.add_user_selection(%{user_id: user.id, option_id: option3.id, lesson_id: lesson2.id})

    [lesson1, lesson2]
  end

  defp assert_lesson_render(lv) do
    assert has_element?(lv, ~s|h3:fl-icontains("lesson 1!")|)
    assert has_element?(lv, ~s|h3:fl-icontains("lesson 2!")|)
    assert has_element?(lv, ~s|span:fl-icontains("3.0")|)
    assert has_element?(lv, ~s|span:fl-icontains("7.0")|)
  end

  defp assert_user_selections(lv, lesson1, lesson2) do
    assert has_element?(lv, ~s|#lessons-#{lesson1.id} p:fl-icontains("option 2!")|)
    refute has_element?(lv, ~s|#lessons-#{lesson1.id} p:fl-icontains("option 1!")|)

    refute has_element?(lv, ~s|#lessons-#{lesson2.id} p:fl-icontains("option 3!")|)
    assert has_element?(lv, ~s|#lessons-#{lesson2.id} h4:fl-icontains("all answers were correct.")|)
  end
end
