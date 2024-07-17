defmodule ZoonkWeb.PlayViewLiveTest do
  use ZoonkWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Zoonk.Fixtures.Content

  alias Zoonk.Accounts
  alias Zoonk.Content
  alias Zoonk.Content.UserSelection
  alias Zoonk.Repo
  alias Zoonk.Storage

  @select_form "#play"

  describe "play view (non-authenticated user)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn, school: school} do
      course = course_fixture(%{school_id: school.id})
      lesson = lesson_fixture(%{course_id: course.id})

      result = get(conn, ~p"/c/#{course.slug}/#{lesson.id}")
      assert redirected_to(result) == "/users/login"
    end
  end

  describe "play view (allow guests)" do
    setup do
      set_school(%{conn: build_conn()}, %{allow_guests?: true})
    end

    test "renders the page", %{conn: conn, school: school} do
      course = course_fixture(%{school_id: school.id})
      lesson = lesson_fixture(%{course_id: course.id})
      generate_steps(lesson)

      conn = get(conn, ~p"/c/#{course.slug}/#{lesson.id}")
      assert redirected_to(conn) == ~p"/c/#{course.slug}/#{lesson.id}"

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")
      assert has_element?(lv, ~s|blockquote p:fl-icontains("step 1!")|)
    end
  end

  describe "play view (private course, non course user)" do
    setup do
      course_setup(%{conn: build_conn()}, public_course?: false, course_user: nil)
    end

    test "returns 403", %{conn: conn, course: course} do
      assert_403(conn, course)
    end
  end

  describe "play view (private course, pending course user)" do
    setup do
      course_setup(%{conn: build_conn()}, public_course?: false, course_user: :pending)
    end

    test "returns 403", %{conn: conn, course: course} do
      assert_403(conn, course)
    end
  end

  describe "play view (public course, non course user)" do
    setup do
      course_setup(%{conn: build_conn()}, public_course?: true, course_user: nil)
    end

    test "automatically enrolls users", %{conn: conn, course: course, user: user} do
      assert Content.get_course_user_by_id(course.id, user.id) == nil

      lesson = lesson_fixture(%{course_id: course.id})
      generate_steps(lesson)

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")

      assert Content.get_course_user_by_id(course.id, user.id) != nil

      assert has_element?(lv, "blockquote p", "step 1!")
    end
  end

  describe "play view (course user)" do
    setup :course_setup

    test "completes a lesson", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      generate_steps(lesson)
      lessons = Content.list_lesson_steps(lesson)

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")

      # image options
      refute has_element?(lv, ~s|li a span:fl-icontains("Home")|)
      refute has_element?(lv, ~s|img[alt="option 1!"]|)
      assert has_element?(lv, ~s|img[alt="option 2!"]|)

      assert_first_step(lv, lessons)
      assert_second_step(lv, lessons)
      assert_third_step(lv, lessons)
      assert_fourth_step(conn, lv, lessons, course)
    end

    test "returns an error if trying to play a lesson from another course", %{conn: conn, course: course} do
      other_course = course_fixture(%{school_id: course.school_id})
      other_lesson = lesson_fixture(%{course_id: other_course.id})
      generate_steps(other_lesson)

      assert_error_sent 404, fn -> get(conn, ~p"/c/#{course.slug}/#{other_lesson.id}") end
    end

    test "returns an error if trying to play an unpublished lesson", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id, published?: false})
      generate_steps(lesson)

      assert_error_sent 404, fn -> get(conn, ~p"/c/#{course.slug}/#{lesson.id}") end
    end

    test "doesn't play sound effects when disabled", %{conn: conn, course: course, user: user} do
      Accounts.update_user_settings(user, %{sound_effects?: false})
      lesson = lesson_fixture(%{course_id: course.id})
      generate_steps(lesson)

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")

      refute has_element?(lv, ~s|form[phx-hook="LessonSoundEffect"]|)
    end

    test "plays sound effects when enabled", %{conn: conn, course: course, user: user} do
      Accounts.update_user_settings(user, %{sound_effects?: true})
      lesson = lesson_fixture(%{course_id: course.id})
      generate_steps(lesson)

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")

      assert has_element?(lv, ~s|form[phx-hook="LessonSoundEffect"]|)
    end

    test "embeds youtube videos when available", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, content: "watch the video: https://www.youtube.com/watch?v=12345678901"})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")

      assert has_element?(lv, "p", "watch the video:")
      refute has_element?(lv, "p", "https://www.youtube.com/watch?v=12345678901")
      assert has_element?(lv, "iframe[src='https://www.youtube-nocookie.com/embed/12345678901']")
    end

    test "displays suggested courses when available", %{conn: conn, school: school, course: course1} do
      course2 = course_fixture(%{school_id: school.id})
      course3 = course_fixture(%{school_id: school.id})

      lesson = lesson_fixture(%{course_id: course1.id})
      step = lesson_step_fixture(%{lesson_id: lesson.id})

      Content.add_step_suggested_course(%{lesson_step_id: step.id, course_id: course2.id})
      Content.add_step_suggested_course(%{lesson_step_id: step.id, course_id: course3.id})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course1.slug}/#{lesson.id}")

      assert has_element?(lv, "a", course2.name)
      assert has_element?(lv, "a", course3.name)
    end

    test "answers an open-ended question", %{conn: conn, course: course, user: user} do
      lesson = lesson_fixture(%{course_id: course.id})
      step = lesson_step_fixture(%{lesson_id: lesson.id, content: "question?", kind: :open_ended, order: 1})
      lesson_step_fixture(%{lesson_id: lesson.id, content: "step 2 question", kind: :readonly, order: 2})

      refute Repo.get_by(UserSelection, user_id: user.id, step_id: step.id)

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")

      assert has_element?(lv, "blockquote p", "question?")
      refute has_element?(lv, "blockquote p", "step 2 question")

      lv |> form(@select_form, %{answer: "answer!"}) |> render_submit()

      assert has_element?(lv, "blockquote p", "step 2 question")
      assert Repo.get_by(UserSelection, user_id: user.id, step_id: step.id).answer == "answer!"
    end

    test "displays a 10 score when the lesson has only one readonly step", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      lesson_step_fixture(%{lesson_id: lesson.id, content: "read only step", kind: :readonly})

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")

      assert has_element?(lv, "blockquote p", "read only step")
      lv |> form(@select_form) |> render_submit()
      assert_redirected(lv, ~p"/c/#{course.slug}/#{lesson.id}/completed")

      {:ok, view, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}/completed")

      assert has_element?(view, "h1", "Perfect!")
      assert has_element?(view, "span", "10.0")
      assert has_element?(view, "p", "You got all the answers correct!")
    end
  end

  defp assert_403(conn, course) do
    lesson = lesson_fixture(%{course_id: course.id})
    assert_error_sent 403, fn -> get(conn, ~p"/c/#{course.slug}/#{lesson.id}") end
  end

  defp assert_first_step(lv, lessons) do
    assert has_element?(lv, ~s|blockquote p:fl-icontains("step 1!")|)
    assert has_element?(lv, ~s|button *:fl-icontains("confirm")|)

    step = hd(lessons)
    first_option = hd(step.options)

    assert has_element?(lv, ~s|input[id="select-option-#{first_option.id}"]|)
    refute has_element?(lv, "textarea")

    lv |> form(@select_form, %{selected_option: get_correct_option(step.options)}) |> render_submit()

    assert has_element?(lv, ~s|div[role="alert"] h3:fl-icontains("well done!")|)
  end

  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  defp assert_second_step(lv, lessons) do
    lv |> form(@select_form) |> render_submit()

    refute has_element?(lv, ~s|blockquote p:fl-icontains("step 1!")|)
    assert has_element?(lv, ~s|blockquote p:fl-icontains("step 2!")|)
    assert has_element?(lv, ~s|button *:fl-icontains("confirm")|)

    step = Enum.at(lessons, 1)
    first_option = hd(step.options)

    assert has_element?(lv, ~s|input[id="select-option-#{first_option.id}"]|)

    lv |> form(@select_form, %{selected_option: get_incorrect_option(step.options)}) |> render_submit()

    assert has_element?(lv, ~s|div[role="alert"] h4:fl-icontains("feedback 2!")|)
  end

  defp assert_third_step(lv, lessons) do
    lv |> form(@select_form) |> render_submit()

    refute has_element?(lv, ~s|blockquote p:fl-icontains("step 1!")|)
    refute has_element?(lv, ~s|blockquote p:fl-icontains("step 2!")|)
    assert has_element?(lv, ~s|blockquote p:fl-icontains("step 3!")|)

    step = Enum.at(lessons, 2)
    file_url = Storage.get_url(step.image)

    assert has_element?(lv, ~s|img[src="#{file_url}"]|)
  end

  defp assert_fourth_step(conn, lv, lessons, course) do
    lv |> form(@select_form) |> render_submit()

    assert has_element?(lv, ~s|blockquote p:fl-icontains("step 4!")|)
    assert has_element?(lv, ~s|button *:fl-icontains("next step")|)

    step = Enum.at(lessons, 3)

    assert {:ok, _lv, _html} =
             lv
             |> form(@select_form)
             |> render_submit()
             |> follow_redirect(conn, ~p"/c/#{course.slug}/#{step.lesson_id}/completed")
  end

  defp generate_steps(lesson) do
    Enum.each(1..4, fn order ->
      content = "step #{order}!"
      image = if order == 3, do: "img.png"
      kind = if order == 4, do: :readonly, else: :quiz

      step = lesson_step_fixture(%{lesson_id: lesson.id, kind: kind, content: content, image: image, order: order})

      # Make sure it works even when the last step doesn't have options.
      unless order == 4, do: generate_options(step, order)
    end)
  end

  defp generate_options(_step, 3), do: nil

  defp generate_options(step, _step_order) do
    Enum.each(1..4, fn order ->
      image = if order == 2, do: "img.png"
      feedback = unless order == 1, do: "feedback #{order}!"
      correct? = order == 1 or order == 4

      step_option_fixture(%{lesson_step_id: step.id, correct?: correct?, image: image, feedback: feedback, title: "option #{order}!"})
    end)
  end

  defp get_correct_option(options), do: Enum.find(options, fn option -> option.correct? end).id
  defp get_incorrect_option(options), do: Enum.find(options, fn option -> not option.correct? end).id
end
