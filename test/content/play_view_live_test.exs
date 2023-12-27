defmodule UneebeeWeb.PlayViewLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Content
  import Uneebee.Fixtures.Organizations

  alias Uneebee.Accounts
  alias Uneebee.Content
  alias Uneebee.Organizations

  @select_form "#select-option"

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

    test "doesn't show the play page if the school doesn't have a subscription", %{conn: conn, school: school, course: course} do
      parent_school = school_fixture(%{school_id: school.id})
      Organizations.update_school(school, %{school_id: parent_school.id})

      Enum.each(1..3, fn _idx -> school_user_fixture(%{school: school}) end)

      lesson = lesson_fixture(%{course_id: course.id})
      generate_steps(lesson)

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")

      refute has_element?(lv, "blockquote p", "step 1!")
      assert has_element?(lv, "h1", "Subscription expired")
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

    assert has_element?(lv, ~s|img[src="#{step.image}"]|)
  end

  defp assert_fourth_step(conn, lv, lessons, course) do
    lv |> form(@select_form) |> render_submit()

    assert has_element?(lv, ~s|blockquote p:fl-icontains("step 4!")|)
    assert has_element?(lv, ~s|button *:fl-icontains("next step")|)

    step = Enum.at(lessons, 3)

    assert {:ok, _conn} =
             lv
             |> form(@select_form)
             |> render_submit()
             |> follow_redirect(conn, ~p"/c/#{course.slug}/#{step.lesson_id}/completed")
  end

  defp generate_steps(lesson) do
    Enum.each(1..4, fn order ->
      content = "step #{order}!"
      image = if order == 3, do: "/uploads/img.png"

      step = lesson_step_fixture(%{lesson_id: lesson.id, content: content, image: image, order: order})

      # Make sure it works even when the last step doesn't have options.
      if order != 4, do: generate_options(step, order)
    end)
  end

  defp generate_options(_step, 3), do: nil

  defp generate_options(step, _step_order) do
    Enum.each(1..4, fn order ->
      image = if order == 2, do: "/uploads/img.png"
      feedback = if order != 1, do: "feedback #{order}!"
      correct? = order == 1 or order == 4

      step_option_fixture(%{lesson_step_id: step.id, correct?: correct?, image: image, feedback: feedback, title: "option #{order}!"})
    end)
  end

  defp get_correct_option(options), do: Enum.find(options, fn option -> option.correct? end).id
  defp get_incorrect_option(options), do: Enum.find(options, fn option -> not option.correct? end).id
end
