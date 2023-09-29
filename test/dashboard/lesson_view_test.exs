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
      result = get(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}")
      assert redirected_to(result) == "/users/login"
    end
  end

  describe "lesson view (school teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :teacher, course_user: nil)
    end

    test "returns 403", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}") end)
    end
  end

  describe "lesson view (student)" do
    setup :course_setup

    test "returns 403", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}") end)
    end
  end

  describe "lesson view (course teacher)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :teacher, course_user: :teacher)
    end

    test "publishes a lesson", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id, published?: false})
      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}")

      assert has_element?(lv, ~s|li[aria-current=page] span:fl-icontains("content")|)

      result = lv |> element("button", "Publish") |> render_click()
      assert result =~ "Lesson published!"
      assert result =~ "Unpublish"

      updated_lesson = Content.get_lesson!(lesson.id)
      assert updated_lesson.published?
    end

    test "unpublishes a lesson", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id, published?: true})
      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}")

      assert has_element?(lv, ~s|li[aria-current=page] span:fl-icontains("content")|)

      result = lv |> element("button", "Unpublish") |> render_click()
      assert result =~ "Lesson unpublished!"
      assert result =~ "Publish"

      updated_lesson = Content.get_lesson!(lesson.id)
      refute updated_lesson.published?
    end

    test "renders the step list", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})

      text_steps =
        Enum.map(1..3, fn i ->
          lesson_step_fixture(%{lesson_id: lesson.id, kind: :text, order: i, content: "Text step #{i}"})
        end)

      image_step = lesson_step_fixture(%{lesson_id: lesson.id, kind: :image, content: "/uploads/image.png", order: 4})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}")

      Enum.each(text_steps, fn step -> assert has_element?(lv, ~s|dt:fl-contains("#{step.content}")|) end)
      assert has_element?(lv, ~s|img[src="#{image_step.content}"]|)
    end

    test "deletes a step", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step = lesson_step_fixture(%{lesson_id: lesson.id, kind: :text, order: 1, content: "Text step 1"})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}")

      assert has_element?(lv, ~s|dt:fl-contains("Text step 1")|)

      lv |> element("button", "Remove step") |> render_click()

      refute has_element?(lv, ~s|dt:fl-contains("Text step 1")|)

      assert_raise Ecto.NoResultsError, fn -> Uneebee.Repo.get!(LessonStep, lesson_step.id) end
    end

    test "adds a text step", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})

      Enum.each(1..3, fn i ->
        lesson_step_fixture(%{lesson_id: lesson.id, kind: :text, order: i, content: "Text step #{i}"})
      end)

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}")

      result = lv |> form("#step-form", lesson_step: %{content: "Text step 4"}) |> render_submit()

      assert result =~ "Step created!"
      assert has_element?(lv, ~s|dt:fl-contains("Text step 4")|)
    end

    test "cannot have more than 20 steps", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})

      Enum.each(1..20, fn i ->
        lesson_step_fixture(%{lesson_id: lesson.id, kind: :text, order: i, content: "Text step #{i}"})
      end)

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}")

      result = lv |> form("#step-form", lesson_step: %{content: "Text step 21"}) |> render_submit()

      assert result =~ "You cannot have more than 20 steps in a lesson"
      refute has_element?(lv, ~s|dt:fl-contains("Text step 21")|)
    end

    test "renders all options for a step", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step = lesson_step_fixture(%{lesson_id: lesson.id})
      option = step_option_fixture(%{lesson_step_id: lesson_step.id})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}")

      assert has_element?(lv, ~s|a:fl-contains("#{option.title}")|)
    end

    test "deletes an option", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step = lesson_step_fixture(%{lesson_id: lesson.id})
      option = step_option_fixture(%{lesson_step_id: lesson_step.id})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}")

      assert has_element?(lv, ~s|a:fl-contains("#{option.title}")|)

      {:ok, updated_lv, _html} =
        lv
        |> element("button", "Delete option")
        |> render_click()
        |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}")

      refute has_element?(updated_lv, ~s|a:fl-contains("#{option.title}")|)

      assert_raise Ecto.NoResultsError, fn -> Content.get_step_option!(option.id) end
    end

    test "adds an option", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}")

      refute has_element?(lv, ~s|a:fl-icontains("untitled option")|)

      {:ok, updated_lv, _html} =
        lv
        |> element("button", "Add option")
        |> render_click()
        |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}")

      assert has_element?(updated_lv, ~s|a:fl-icontains("untitled option")|)
    end

    test "updates an option", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step = lesson_step_fixture(%{lesson_id: lesson.id})
      option = step_option_fixture(%{lesson_step_id: lesson_step.id, title: "New option 1"})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}")

      {:ok, update_lv, _html} =
        lv
        |> element("a", option.title)
        |> render_click()
        |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/o/#{option.id}")

      {:ok, submitted_lv, _html} =
        update_lv
        |> form("#option-form", step_option: %{title: "Updated option!"})
        |> render_submit()
        |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}")

      assert has_element?(submitted_lv, ~s|a:fl-contains("Updated option!")|)
      assert Content.get_step_option!(option.id).title == "Updated option!"
    end
  end
end
