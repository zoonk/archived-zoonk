defmodule UneebeeWeb.PlayViewLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Content

  alias Uneebee.Content

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

  describe "play view (non course user)" do
    setup do
      course_setup(%{conn: build_conn()}, course_user: nil)
    end

    test "returns 403", %{conn: conn, course: course} do
      assert_403(conn, course)
    end
  end

  describe "play view (pending course user)" do
    setup do
      course_setup(%{conn: build_conn()}, course_user: :pending)
    end

    test "returns 403", %{conn: conn, course: course} do
      assert_403(conn, course)
    end
  end

  describe "play view (story, course user)" do
    setup :course_setup

    test "completes a lesson", %{conn: conn, course: course} do
      lesson = lesson_fixture(%{course_id: course.id})
      generate_steps(lesson)
      lessons = Content.list_lesson_steps(lesson)

      {:ok, lv, _html} = live(conn, ~p"/c/#{course.slug}/#{lesson.id}")

      refute has_element?(lv, ~s|li a span:fl-icontains("Home")|)

      # image options
      refute has_element?(lv, ~s|img[alt="option 1!"]|)
      assert has_element?(lv, ~s|img[alt="option 2!"]|)

      assert_first_step(lv, lessons)
      assert_second_step(lv, lessons)
      assert_third_step(lv, lessons)
      assert_fourth_step(conn, lv, lessons, course)
    end
  end

  defp assert_403(conn, course) do
    lesson = lesson_fixture(%{course_id: course.id})
    assert_error_sent 403, fn -> get(conn, ~p"/c/#{course.slug}/#{lesson.id}") end
  end

  defp assert_first_step(lv, lessons) do
    assert has_element?(lv, ~s|section p:fl-icontains("step 1!")|)
    refute has_element?(lv, ~s|section p:fl-icontains("step 2!")|)
    assert has_element?(lv, ~s|button:fl-icontains("confirm")|)

    step = hd(lessons)
    first_option = hd(step.options)

    assert has_element?(lv, ~s|input[id="select-option-#{first_option.id}"]|)

    lv |> form(@select_form, %{selected_option: get_correct_option(step.options)}) |> render_submit()

    assert has_element?(lv, ~s|span:fl-icontains("You selected: option 1!. Well done!")|)
    refute has_element?(lv, ~s|span:fl-icontains("Correct answer: option 1!.")|)
    refute has_element?(lv, ~s|input[id="select-option-#{first_option.id}"]|)
  end

  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  defp assert_second_step(lv, lessons) do
    assert has_element?(lv, ~s|section p:fl-icontains("step 1!")|)
    assert has_element?(lv, ~s|section p:fl-icontains("step 2!")|)
    refute has_element?(lv, ~s|section p:fl-icontains("step 3!")|)
    assert has_element?(lv, ~s|button:fl-icontains("confirm")|)

    step = Enum.at(lessons, 1)
    first_option = hd(step.options)

    assert has_element?(lv, ~s|input[id="select-option-#{first_option.id}"]|)

    lv |> form(@select_form, %{selected_option: get_incorrect_option(step.options)}) |> render_submit()

    assert has_element?(lv, ~s|span:fl-icontains("You selected: option 2!. feedback 2!")|)
    assert has_element?(lv, ~s|span:fl-icontains("Correct answer: option 1!.")|)
    refute has_element?(lv, ~s|input[id="select-option-#{first_option.id}"]|)
  end

  defp assert_third_step(lv, lessons) do
    assert has_element?(lv, ~s|section p:fl-icontains("step 1!")|)
    assert has_element?(lv, ~s|section p:fl-icontains("step 2!")|)
    refute has_element?(lv, ~s|section p:fl-icontains("step 4!")|)

    step = Enum.at(lessons, 2)

    assert has_element?(lv, ~s|img[src="#{step.content}"]|)
    refute has_element?(lv, @select_form)

    lv |> element("button", "Next step") |> render_click()
  end

  defp assert_fourth_step(conn, lv, lessons, course) do
    assert has_element?(lv, ~s|section p:fl-icontains("step 1!")|)
    assert has_element?(lv, ~s|section p:fl-icontains("step 2!")|)
    assert has_element?(lv, ~s|section p:fl-icontains("step 4!")|)
    assert has_element?(lv, ~s|button:fl-icontains("confirm")|)

    step = Enum.at(lessons, 3)
    first_option = hd(step.options)
    image_option = get_image_option(step.options)

    assert has_element?(lv, ~s|input[id="select-option-#{first_option.id}"]|)
    assert has_element?(lv, ~s|label img[src="#{image_option}"]|)

    assert {:ok, _conn} =
             lv
             |> form(@select_form, %{selected_option: first_option.id})
             |> render_submit()
             |> follow_redirect(conn, ~p"/c/#{course.slug}/#{step.lesson_id}/completed")
  end

  defp generate_steps(lesson) do
    Enum.each(1..4, fn order ->
      kind = if order == 3, do: :image, else: :text
      content = if order == 3, do: "/uploads/img.png", else: "step #{order}!"

      step = lesson_step_fixture(%{lesson_id: lesson.id, kind: kind, content: content, order: order})
      generate_options(step, order)
    end)
  end

  defp generate_options(_step, 3), do: nil

  defp generate_options(step, _step_order) do
    Enum.each(1..3, fn order ->
      image = if order == 2, do: "/uploads/img.png"
      feedback = if order != 1, do: "feedback #{order}!"

      step_option_fixture(%{lesson_step_id: step.id, correct?: order == 1, image: image, feedback: feedback, title: "option #{order}!"})
    end)
  end

  defp get_correct_option(options), do: Enum.find(options, fn option -> option.correct? end).id
  defp get_incorrect_option(options), do: Enum.find(options, fn option -> not option.correct? end).id
  defp get_image_option(options), do: Enum.find(options, fn option -> option.image != nil end).image
end
