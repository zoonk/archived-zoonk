defmodule UneebeeWeb.DashboardLessonViewLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Content
  import UneebeeWeb.TestHelpers.Upload

  alias Uneebee.Content
  alias Uneebee.Content.CourseUtils
  alias Uneebee.Content.LessonStep

  @lesson_form "#lesson-form"

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

    test "switches to a different lesson", %{conn: conn, course: course} do
      lesson1 = lesson_fixture(%{course_id: course.id})
      lesson2 = lesson_fixture(%{course_id: course.id})

      lesson_step_fixture(%{lesson: lesson1, order: 1})
      lesson_step_fixture(%{lesson: lesson2, order: 1})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson1.id}/s/1")

      assert has_element?(lv, "option[selected]", lesson1.name)

      {:ok, updated_lv, _html} =
        lv
        |> form("#select-lesson", lesson: lesson2.id)
        |> render_change()
        |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson2.id}/s/1")

      assert has_element?(updated_lv, "option[selected]", lesson2.name)
    end

    test "creates a new lesson", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson: lesson, order: 1})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      {:ok, updated_lv, _html} =
        lv
        |> form("#select-lesson", lesson: "new-lesson")
        |> render_change()
        |> follow_redirect(conn)

      assert has_element?(updated_lv, "option[selected]", "Lesson 2")
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

      assert has_element?(lv, ~s|a span:fl-contains("Text step 2")|)

      lv |> element("button", "Remove step") |> render_click()

      refute has_element?(lv, ~s|a:fl-contains("Text step 2")|)
      assert_raise Ecto.NoResultsError, fn -> Uneebee.Repo.get!(LessonStep, lesson_step.id) end
    end

    test "deletes a lesson", %{conn: conn, course: course} do
      lesson1 = lesson_fixture(%{course_id: course.id, order: 1})
      lesson2 = lesson_fixture(%{course_id: course.id, order: 2})
      lesson3 = lesson_fixture(%{course_id: course.id, order: 3})
      lesson4 = lesson_fixture(%{course_id: course.id, order: 4})
      lesson5 = lesson_fixture(%{course_id: course.id, order: 5})
      lesson_step_fixture(%{lesson_id: lesson1.id, order: 1, content: "step lesson 1"})
      lesson_step_fixture(%{lesson_id: lesson2.id, order: 1, content: "step lesson 2"})
      lesson_step_fixture(%{lesson_id: lesson3.id, order: 1, content: "step lesson 3"})
      lesson_step_fixture(%{lesson_id: lesson4.id, order: 1, content: "step lesson 4"})
      lesson_step_fixture(%{lesson_id: lesson5.id, order: 1, content: "step lesson 5"})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson1.id}/s/1")

      assert has_element?(lv, ~s|a span:fl-contains("step lesson 1")|)
      refute has_element?(lv, ~s|a span:fl-contains("step lesson 2")|)

      assert {:ok, updated_lv, _html} =
               lv
               |> element("button", "Delete lesson")
               |> render_click()
               |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson2.id}/s/1")

      assert has_element?(updated_lv, ~s|a span:fl-contains("step lesson 2")|)
      refute has_element?(updated_lv, ~s|a span:fl-contains("step lesson 1")|)

      assert_raise Ecto.NoResultsError, fn -> Content.get_lesson!(lesson1.id) end
      assert Content.count_lessons(course.id) == 4
    end

    test "redirects to the course view when deleting the only lesson", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id, order: 1})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 1})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      assert {:ok, updated_lv, _html} =
               lv
               |> element("button", "Delete lesson")
               |> render_click()
               |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}")

      assert has_element?(updated_lv, ~s|button:fl-icontains("+ Lesson")|)

      assert_raise Ecto.NoResultsError, fn -> Content.get_lesson!(lesson.id) end
    end

    test "hides the remove step button when it's the only step", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson: lesson})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      refute has_element?(lv, ~s|button:fl-contains("Remove step")|)
    end

    test "updates a step", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      step = lesson_step_fixture(%{lesson_id: lesson.id, order: 1, content: "Text step 1"})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      lv |> element("#step-edit-#{step.id}", "Text step 1") |> render_click()
      lv |> form("#step-form", lesson_step: %{content: "Updated step!"}) |> render_submit()

      assert has_element?(lv, ~s|a span:fl-contains("Updated step!")|)
      assert Content.get_lesson_step_by_order(lesson, 1).content == "Updated step!"
    end

    test "updates a step image", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      long_content = String.duplicate("a", CourseUtils.max_length(:step_content))
      lesson_step_fixture(%{lesson_id: lesson.id, order: 1, content: long_content, image: "https://someimage.png"})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      lv |> element("#step-img-link") |> render_click()

      assert has_element?(lv, "button", "Remove")
      assert_file_upload(lv, "step_img_upload")

      updated_step = Content.get_lesson_step_by_order(lesson, 1)
      assert String.starts_with?(updated_step.image, "/uploads")
    end

    test "adds an image to a step", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 1, content: "Text step 1", image: nil})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      lv |> element("a", "Click to add an image to this step.") |> render_click()

      refute has_element?(lv, "#remove-step_img_upload")
      assert_file_upload(lv, "step_img_upload")

      updated_step = Content.get_lesson_step_by_order(lesson, 1)
      assert String.starts_with?(updated_step.image, "/uploads")
    end

    test "removes an image from a step", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 1, content: "Text step 1", image: "https://someimage.png"})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1/image")

      lv |> element("#remove-step_img_upload") |> render_click()

      updated_step = Content.get_lesson_step_by_order(lesson, 1)
      assert updated_step.image == nil
    end

    test "adds a text step", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})

      Enum.each(1..3, fn i -> lesson_step_fixture(%{lesson_id: lesson.id, order: i, content: "Text step #{i}"}) end)

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      lv |> element("button", "+") |> render_click()

      assert has_element?(lv, ~s|a[href="/dashboard/c/#{course.slug}/l/#{lesson.id}/s/4/edit"] span:fl-icontains("untitled step")|)
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

      feedback = String.duplicate("a", CourseUtils.max_length(:option_feedback))
      title = String.duplicate("a", CourseUtils.max_length(:option_title))

      lv |> element("a", option.title) |> render_click()
      lv |> form("#option-form", step_option: %{feedback: feedback, title: title}) |> render_submit()

      assert Content.get_step_option!(option.id).feedback == feedback
      assert Content.get_step_option!(option.id).title == title
    end

    test "updates an option image", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step = lesson_step_fixture(%{lesson_id: lesson.id, order: 1})
      option = step_option_fixture(%{lesson_step_id: lesson_step.id, title: "New option 1"})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      lv |> element("#option-#{option.id}-image-link") |> render_click()
      assert_file_upload(lv, "option_img")

      updated_option = Content.get_step_option!(option.id)
      assert String.starts_with?(updated_option.image, "/uploads")
    end

    test "removes an image from an option", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step = lesson_step_fixture(%{lesson_id: lesson.id, order: 1})
      option = step_option_fixture(%{lesson_step_id: lesson_step.id, title: "New option 1", image: "https://someimage.png"})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1/o/#{option.id}/image")

      lv |> element("button", "Remove") |> render_click()

      updated_option = Content.get_step_option!(option.id)
      assert updated_option.image == nil
    end

    test "edits a lesson information", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 1})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 2})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/2")

      {:ok, updated_lv, _html} =
        lv
        |> element("a", "Edit lesson")
        |> render_click()
        |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/2/edit_step")

      assert_lesson_name(updated_lv)
      assert_lesson_description(updated_lv)

      attrs = %{name: "New lesson name", description: "New lesson description"}
      updated_lv |> form(@lesson_form, lesson: attrs) |> render_submit()

      assert has_element?(updated_lv, ~s|option[selected]:fl-icontains("#{attrs.name}")|)

      updated_lesson = Content.get_lesson!(lesson.id)
      assert updated_lesson.name == attrs.name
      assert updated_lesson.description == attrs.description
    end
  end

  defp assert_403(conn, course) do
    lesson = lesson_fixture(%{course_id: course.id})
    lesson_step_fixture(%{lesson: lesson, order: 1})
    assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1") end)
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
