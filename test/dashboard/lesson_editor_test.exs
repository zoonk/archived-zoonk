defmodule ZoonkWeb.DashboardLessonEditorLiveTest do
  use ZoonkWeb.ConnCase, async: true

  import Mox
  import Phoenix.LiveViewTest
  import Zoonk.Fixtures.Accounts
  import Zoonk.Fixtures.Content
  import Zoonk.Fixtures.Storage

  alias Zoonk.Content
  alias Zoonk.Content.CourseUtils
  alias Zoonk.Content.LessonStep
  alias Zoonk.Repo
  alias Zoonk.Storage.SchoolObject
  alias Zoonk.Storage.StorageAPIMock

  @lesson_form "#lesson-form"

  setup :verify_on_exit!

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

    test "returns an error if trying to view a lesson from another course", %{conn: conn, course: course} do
      other_course = course_fixture(%{school_id: course.school_id})
      lesson = lesson_fixture(%{course: other_course})
      lesson_step_fixture(%{lesson: lesson, order: 1})

      assert_error_sent(404, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1") end)
    end

    test "publishes a lesson", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id, published?: false})
      lesson_step_fixture(%{lesson: lesson, order: 1})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("editor")|)

      result = lv |> element("button", "Publish") |> render_click()
      assert result =~ "Unpublish"

      updated_lesson = Content.get_lesson!(lesson.id)
      assert updated_lesson.published?
    end

    test "unpublishes a lesson", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id, published?: true})
      lesson_step_fixture(%{lesson: lesson, order: 1})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("editor")|)

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

    test "creates a new lesson", %{conn: conn, course: course, lesson: lesson} do
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
      assert_raise Ecto.NoResultsError, fn -> Zoonk.Repo.get!(LessonStep, lesson_step.id) end
    end

    test "deletes a lesson", %{conn: conn, course: course, lesson: lesson1} do
      lesson2 = lesson_fixture(%{course_id: course.id, order: 2})
      lesson3 = lesson_fixture(%{course_id: course.id, order: 3})
      lesson4 = lesson_fixture(%{course_id: course.id, order: 4})
      lesson5 = lesson_fixture(%{course_id: course.id, order: 5})
      lesson_step_fixture(%{lesson_id: lesson2.id, order: 1, content: "step lesson 2"})
      lesson_step_fixture(%{lesson_id: lesson3.id, order: 1, content: "step lesson 3"})
      lesson_step_fixture(%{lesson_id: lesson4.id, order: 1, content: "step lesson 4"})
      lesson_step_fixture(%{lesson_id: lesson5.id, order: 1, content: "step lesson 5"})

      assert Content.count_lessons(course.id) == 5

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson2.id}/s/1")

      assert has_element?(lv, ~s|a span:fl-contains("step lesson 2")|)
      refute has_element?(lv, ~s|a span:fl-contains("step lesson 3")|)

      assert {:ok, updated_lv, _html} =
               lv
               |> element("button", "Delete lesson")
               |> render_click()
               |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson1.id}/s/1")

      refute has_element?(updated_lv, ~s|a span:fl-contains("step lesson 2")|)

      assert_raise Ecto.NoResultsError, fn -> Content.get_lesson!(lesson2.id) end
      assert Content.count_lessons(course.id) == 4
    end

    test "does not allow to delete the only lesson", %{conn: conn, course: course, lesson: lesson} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      refute has_element?(lv, ~s|button *:fl-icontains("delete lesson")|)
    end

    test "hides the remove step button when it's the only step", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson: lesson})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      refute has_element?(lv, ~s|button *:fl-contains("Remove step")|)
    end

    test "updates a step", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      step = lesson_step_fixture(%{lesson_id: lesson.id, order: 1, content: "Text step 1"})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      lv |> element("#step-edit-#{step.id}", "Text step 1") |> render_click()
      lv |> form("#step-form", lesson_step: %{content: "Updated step!"}) |> render_submit()

      assert has_element?(lv, ~s|a span:fl-contains("Updated step!")|)
      assert Content.get_lesson_step_by_order(lesson.id, 1).content == "Updated step!"
    end

    test "removes an image from a step", %{conn: conn, course: course} do
      expect(StorageAPIMock, :delete, fn _key -> {:ok, %{}} end)

      school_object = school_object_fixture(%{school_id: course.school_id})

      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 1, content: "Text step 1", image: school_object.key})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1/image")

      lv |> element("#remove-step_img_upload") |> render_click()

      assert Content.get_lesson_step_by_order(lesson.id, 1).image == nil

      # the image should have been removed from the school object table too
      assert Repo.get_by(SchoolObject, key: school_object.key) == nil
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

      refute has_element?(lv, ~s|button *:fl-icontains("+")|)
    end

    test "renders all options for a step", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step = lesson_step_fixture(%{lesson_id: lesson.id, order: 1})
      option = step_option_fixture(%{lesson_step_id: lesson_step.id})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      assert has_element?(lv, ~s|a:fl-contains("#{option.title}")|)
    end

    test "renders how many times an option was selected by users", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step = lesson_step_fixture(%{lesson_id: lesson.id, order: 1})
      option1 = step_option_fixture(%{lesson_step_id: lesson_step.id})
      option2 = step_option_fixture(%{lesson_step_id: lesson_step.id})
      option3 = step_option_fixture(%{lesson_step_id: lesson_step.id})

      user = user_fixture()
      Enum.each(1..3, fn _i -> Content.add_user_selection(%{duration: 5, user_id: user.id, option_id: option1.id, lesson_id: lesson.id, step_id: lesson_step.id}) end)
      Enum.each(1..2, fn _i -> Content.add_user_selection(%{duration: 5, user_id: user.id, option_id: option2.id, lesson_id: lesson.id, step_id: lesson_step.id}) end)

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      assert has_element?(lv, ~s|#option-#{option1.id} span[title="This option was selected 60% of the time."]:fl-icontains("60%")|)
      assert has_element?(lv, ~s|#option-#{option2.id} span[title="This option was selected 40% of the time."]:fl-icontains("40%")|)
      assert has_element?(lv, ~s|#option-#{option3.id} span[title="This option was selected 0% of the time."]:fl-icontains("0%")|)
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

    test "removes an image from an option", %{conn: conn, course: course} do
      expect(StorageAPIMock, :delete, fn _key -> {:ok, %{}} end)

      school_object = school_object_fixture(%{school_id: course.school_id})

      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step = lesson_step_fixture(%{lesson_id: lesson.id, order: 1})
      option = step_option_fixture(%{lesson_step_id: lesson_step.id, title: "New option 1", image: school_object.key})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1/o/#{option.id}/image")

      lv |> element("button", "Remove") |> render_click()

      assert Content.get_step_option!(option.id).image == nil

      # the image should have been removed from the school object table too
      assert Repo.get_by(SchoolObject, key: school_object.key) == nil
    end

    test "edits a lesson information", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 1})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 2})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/2")

      {:ok, updated_lv, _html} =
        lv
        |> element(~s|a[href="/dashboard/c/#{course.slug}/l/#{lesson.id}/s/2/edit_step"]:fl-icontains("edit")|)
        |> render_click()
        |> follow_redirect(conn, edit_lesson_redirect_link(course, lesson))

      assert_lesson_name(updated_lv)
      assert_lesson_description(updated_lv)

      attrs = %{name: "New lesson name", description: "New lesson description"}
      updated_lv |> form(@lesson_form, lesson: attrs) |> render_submit()

      assert has_element?(updated_lv, ~s|option[selected]:fl-icontains("#{attrs.name}")|)

      updated_lesson = Content.get_lesson!(lesson.id)
      assert updated_lesson.name == attrs.name
      assert updated_lesson.description == attrs.description
    end

    test "edits a lesson information in realtime", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 1})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 2})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/2")

      {:ok, view, _html} =
        lv
        |> element(~s|a[href="/dashboard/c/#{course.slug}/l/#{lesson.id}/s/2/edit_step"]:fl-icontains("edit")|)
        |> render_click()
        |> follow_redirect(conn, edit_lesson_redirect_link(course, lesson))

      assert_lesson_name(view)
      assert_lesson_description(view)

      attrs = %{name: "Updated lesson name", description: "Updated lesson description"}
      view |> form(@lesson_form, lesson: attrs) |> render_submit()

      assert has_element?(view, "h1", "Updated lesson name")
      assert has_element?(view, "p", "Updated lesson description")
    end

    test "adds a suggested course", %{conn: conn, school: school, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 1})
      course2 = course_fixture(%{school_id: school.id, name: "Test course"})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      lv |> element("a", "Search course") |> render_click()
      lv |> form("#course-search") |> render_change(%{term: "test"})

      assert {:ok, conn} =
               lv
               |> element("a", course2.name)
               |> render_click()
               |> follow_redirect(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1/suggested_course/#{course2.id}")

      assert redirected_to(conn) == "/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1"

      {:ok, updated_lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      assert has_element?(updated_lv, "dt", course2.name)
    end

    test "removes a suggested course", %{conn: conn, school: school, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      step = lesson_step_fixture(%{lesson_id: lesson.id, order: 1})
      course2 = course_fixture(%{school_id: school.id})
      Content.add_step_suggested_course(%{lesson_step_id: step.id, course_id: course2.id})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      lv |> element("button", course2.name) |> render_click()

      refute has_element?(lv, "dt", course2.name)
      assert Content.list_step_suggested_courses(step.id) == []
    end

    test "adding a new step makes it read-only", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, kind: :quiz, order: 1})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      refute has_element?(lv, "h3", "Answer type")

      lv |> element("button", "+") |> render_click()

      assert has_element?(lv, "h3", "Answer type")
      assert Content.get_lesson_step_by_order(lesson.id, 2).kind == :readonly
    end

    test "updates a step to a quiz kind", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, kind: :readonly, order: 1})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      assert has_element?(lv, "h3", "Answer type")
      refute has_element?(lv, "button", "Add option")

      lv |> element("button", "Quiz") |> render_click()

      assert has_element?(lv, "button", "Add option")
      assert Content.get_lesson_step_by_order(lesson.id, 1).kind == :quiz
    end

    test "updates a step to an open ended kind", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, kind: :readonly, order: 1})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1")

      assert has_element?(lv, "h3", "Answer type")
      refute has_element?(lv, "h3", "Open-ended question")

      lv |> element("button", "Open-ended") |> render_click()

      assert has_element?(lv, "h3", "Open-ended question")
      assert Content.get_lesson_step_by_order(lesson.id, 1).kind == :open_ended
    end

    test "embeds youtube video", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 2, content: "watch video: https://www.youtube.com/watch?v=12345678901"})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/2")

      assert has_element?(lv, "iframe[src='https://www.youtube-nocookie.com/embed/12345678901']")
      assert has_element?(lv, "span", "watch video:")
      refute has_element?(lv, "span", "https://www.youtube.com/watch?v=12345678901")
    end
  end

  defp assert_403(conn, course) do
    lesson = lesson_fixture(%{course_id: course.id})
    lesson_step_fixture(%{lesson: lesson, order: 1})
    assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/1") end)
  end

  defp assert_lesson_name(lv) do
    lv |> element(@lesson_form) |> render_change(lesson: %{name: ""})
    assert has_element?(lv, "div[role='alert']", "can't be blank")
  end

  defp assert_lesson_description(lv) do
    lv |> element(@lesson_form) |> render_change(lesson: %{description: ""})
    assert has_element?(lv, "div[role='alert']", "can't be blank")
  end

  defp edit_lesson_redirect_link(course, lesson) do
    ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/2/edit_step"
  end
end
