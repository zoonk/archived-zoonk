defmodule UneebeeWeb.HomeControllerTest do
  @moduledoc false
  use UneebeeWeb.ConnCase, async: true

  import Uneebee.Fixtures.Content
  import Uneebee.Fixtures.Organizations

  describe "GET / (public school, logged in)" do
    setup :app_setup

    test "redirects to school setup when user exists but school doesn't", %{conn: conn} do
      result = conn |> Map.put(:host, "invalid.org") |> get(~p"/")
      assert redirected_to(result) == ~p"/schools/new"
    end

    test "redirects to the course list when a user never completed a lesson", %{conn: conn} do
      result = get(conn, ~p"/")
      assert redirected_to(result) == ~p"/courses"
    end

    test "redirects to the course view when a user completed a lesson", %{conn: conn, school: school, user: user} do
      course = course_fixture(%{school: school})
      generate_user_lesson(user.id, 0, course: course)

      result = get(conn, ~p"/")
      assert redirected_to(result) == ~p"/c/#{course.slug}"
    end

    test "doesn't redirect to another school's course", %{conn: conn, school: school, user: user} do
      course = course_fixture(%{school: school})

      other_school = school_fixture(%{name: "Other School"})
      other_course = course_fixture(%{school: other_school})

      generate_user_lesson(user.id, -1, course: course)
      generate_user_lesson(user.id, 0, course: other_course)

      result = get(conn, ~p"/")
      assert redirected_to(result) == ~p"/c/#{course.slug}"
    end

    test "redirects to the course list when a user completed courses only from another school", %{conn: conn, school: school, user: user} do
      course_fixture(%{school: school})

      other_school = school_fixture(%{name: "Other School"})
      other_course = course_fixture(%{school: other_school})

      generate_user_lesson(user.id, 0, course: other_course)

      result = get(conn, ~p"/")
      assert redirected_to(result) == ~p"/courses"
    end
  end
end
