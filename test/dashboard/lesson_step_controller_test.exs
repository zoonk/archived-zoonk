defmodule ZoonkWeb.LessonStepControllerTest do
  use ZoonkWeb.ConnCase, async: true

  import Zoonk.Fixtures.Content

  alias Zoonk.Content

  describe "add suggested course (non-authenticated users)" do
    setup :set_school

    test "redirects to login page", %{conn: conn, school: school} do
      course1 = course_fixture(%{school_id: school.id})
      course2 = course_fixture(%{school_id: school.id})

      lesson = lesson_fixture(%{course_id: course1.id})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 1})

      conn = get(conn, ~p"/dashboard/c/#{course1.slug}/l/#{lesson.id}/s/1/suggested_course/#{course2.id}")
      assert redirected_to(conn) == ~p"/users/login"
    end
  end

  describe "add suggested course (students)" do
    setup :course_setup

    test "returns 403", %{conn: conn, school: school, course: course1} do
      course2 = course_fixture(%{school_id: school.id})

      lesson = lesson_fixture(%{course_id: course1.id})
      lesson_step_fixture(%{lesson_id: lesson.id, order: 1})

      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/c/#{course1.slug}/l/#{lesson.id}/s/1/suggested_course/#{course2.id}") end)
    end
  end

  describe "add suggested course (teachers)" do
    setup do
      course_setup(%{conn: build_conn()}, school_user: :teacher, course_user: :teacher)
    end

    test "adds suggested course", %{conn: conn, school: school, course: course1} do
      course2 = course_fixture(%{school_id: school.id})

      lesson = lesson_fixture(%{course_id: course1.id})
      step = lesson_step_fixture(%{lesson_id: lesson.id, order: 1})

      conn = get(conn, ~p"/dashboard/c/#{course1.slug}/l/#{lesson.id}/s/1/suggested_course/#{course2.id}")

      assert redirected_to(conn) == ~p"/dashboard/c/#{course1.slug}/l/#{lesson.id}/s/1"

      suggested_courses = Content.list_step_suggested_courses(step.id)
      assert length(suggested_courses) == 1
      assert Enum.at(suggested_courses, 0).course_id == course2.id
    end
  end
end
