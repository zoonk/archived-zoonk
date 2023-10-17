defmodule UneebeeWeb.DashboardLessonViewLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Content

  alias Uneebee.Content
  alias Uneebee.Content.LessonStep

  describe "lesson view (non-authenticated user)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn, school: school} do
      course = course_fixture(%{school_id: school.id})
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson: lesson, order: 1})
      result = get(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")
      assert redirected_to(result) == "/users/login"
    end
  end

  describe "lesson view (school teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :teacher, course_user: nil)
    end

    test "returns 403", %{conn: conn, course: course} do
      assert_403(conn, course)
    end
  end

  describe "lesson view (student)" do
    setup :course_setup

    test "returns 403", %{conn: conn, course: course} do
      assert_403(conn, course)
    end
  end

  describe "lesson view (course teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :teacher, course_user: :teacher)
    end

    test "publishes a lesson", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id, published?: false})
      lesson_step_fixture(%{lesson: lesson, order: 1})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      assert has_element?(lv, ~s|li[aria-current=page] span:fl-icontains("content")|)

      result = lv |> element("button", "Publish") |> render_click()
      assert result =~ "Unpublish"

      updated_lesson = Content.get_lesson!(lesson.id)
      assert updated_lesson.published?
    end

    test "unpublishes a lesson", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id, published?: true})
      lesson_step_fixture(%{lesson: lesson, order: 1})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      assert has_element?(lv, ~s|li[aria-current=page] span:fl-icontains("content")|)

      result = lv |> element("button", "Unpublish") |> render_click()
      assert result =~ "Publish"

      updated_lesson = Content.get_lesson!(lesson.id)
      refute updated_lesson.published?
    end

    test "renders the step list", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      steps = Enum.map(1..3, fn i -> lesson_step_fixture(%{lesson_id: lesson.id, order: i, content: "Step #{i}"}) end)

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      Enum.each(steps, fn step -> assert has_element?(lv, ~s|a[href="/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{step.order}"]|) end)
    end

    test "deletes a step", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 1, content: "Text step 1"})
      lesson_step = lesson_step_fixture(%{lesson_id: lesson.id, order: 2, content: "Text step 2"})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/2")

      assert has_element?(lv, ~s|a:fl-contains("Text step 2")|)

      lv |> element("button", "Remove step") |> render_click()

      refute has_element?(lv, ~s|a:fl-contains("Text step 2")|)
      assert_raise Ecto.NoResultsError, fn -> Uneebee.Repo.get!(LessonStep, lesson_step.id) end
    end

    test "hides the remove step button when it's the only step", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson: lesson})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      refute has_element?(lv, ~s|button:fl-contains("Remove step")|)
    end

    test "updates a step", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 1, content: "Text step 1"})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      lv |> element("a", "Text step 1") |> render_click()
      lv |> form("#step-form", lesson_step: %{content: "Updated step!"}) |> render_submit()

      assert has_element?(lv, ~s|a:fl-contains("Updated step!")|)
      assert Content.get_lesson_step_by_order(lesson, 1).content == "Updated step!"
    end

    test "adds a text step", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})

      Enum.each(1..3, fn i -> lesson_step_fixture(%{lesson_id: lesson.id, order: i, content: "Text step #{i}"}) end)

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      lv |> element("button", "+") |> render_click()

      assert has_element?(lv, ~s|a[href="/dashboard/c/#{course.slug}/l/#{lesson.id}/s/4/edit"]:fl-icontains("untitled step")|)
    end

    test "cannot have more than 20 steps", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})

      Enum.each(1..20, fn i -> lesson_step_fixture(%{lesson_id: lesson.id, order: i, content: "Text step #{i}"}) end)

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      refute has_element?(lv, ~s|button:fl-icontains("+")|)
    end

    test "renders all options for a step", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step = lesson_step_fixture(%{lesson_id: lesson.id, order: 1})
      option = step_option_fixture(%{lesson_step_id: lesson_step.id})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      assert has_element?(lv, ~s|a:fl-contains("#{option.title}")|)
    end

    test "deletes an option", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step = lesson_step_fixture(%{lesson_id: lesson.id, order: 1})
      option = step_option_fixture(%{lesson_step_id: lesson_step.id})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      assert has_element?(lv, ~s|a:fl-contains("#{option.title}")|)

      lv |> element("button", "Delete option") |> render_click()

      refute has_element?(lv, ~s|a:fl-contains("#{option.title}")|)
      assert_raise Ecto.NoResultsError, fn -> Content.get_step_option!(option.id) end
    end

    test "adds an option", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 1})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      refute has_element?(lv, ~s|a:fl-icontains("untitled option")|)

      lv |> element("button", "Add option") |> render_click()

      assert has_element?(lv, ~s|a:fl-icontains("untitled option")|)
    end

    test "updates an option", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step = lesson_step_fixture(%{lesson_id: lesson.id, order: 1})
      option = step_option_fixture(%{lesson_step_id: lesson_step.id, title: "New option 1"})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      lv |> element("a", option.title) |> render_click()
      lv |> form("#option-form", step_option: %{title: "Updated option!"}) |> render_submit()

      assert has_element?(lv, ~s|a:fl-contains("Updated option!")|)
      assert Content.get_step_option!(option.id).title == "Updated option!"
    end
  end

  defp assert_403(conn, course) do
    lesson = lesson_fixture(%{course_id: course.id})
    lesson_step_fixture(%{lesson: lesson, order: 1})
    assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1") end)
  end
end
