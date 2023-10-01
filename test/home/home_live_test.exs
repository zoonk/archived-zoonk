defmodule UneebeeWeb.HomeControllerTest do
  @moduledoc false
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Content
  import Uneebee.Fixtures.Gamification
  import Uneebee.Fixtures.Organizations

  describe "GET / (public school, logged in)" do
    setup :app_setup

    test "renders the correct language attribute", %{conn: conn} do
      {:ok, _lv, html} = conn |> log_in_user(user_fixture(language: :pt)) |> live(~p"/")
      assert html =~ ~s'<html lang="pt"'
    end

    test "redirects to school setup when user exists but school doesn't", %{conn: conn} do
      result = conn |> Map.put(:host, "invalid.org") |> get(~p"/")
      assert redirected_to(result) == ~p"/schools/new"
    end

    test "lists the last 3 courses a user joined as a student", %{conn: conn, school: school, user: user} do
      courses = Enum.map(1..4, fn idx -> course_fixture(%{school_id: school.id, name: "Course #{idx}"}) end)
      Enum.each(courses, fn course -> course_user_fixture(%{user: user, course: course}) end)

      {:ok, lv, _html} = live(conn, ~p"/")
      refute has_element?(lv, ~s|#my-courses dt:fl-icontains("course 1")|)

      Enum.each(2..4, fn idx -> assert has_element?(lv, ~s|#my-courses dt:fl-icontains("course #{idx}")|) end)
    end

    test "shows how many learning days a user has", %{conn: conn, user: user} do
      Enum.each(1..3, fn idx -> generate_user_lesson(user.id, -idx) end)
      {:ok, lv, _html} = live(conn, ~p"/")
      assert has_element?(lv, ~s|#learning-days:fl-contains("3")|)
    end

    test "shows how many medals a user has", %{conn: conn, user: user} do
      Enum.each(1..3, fn _idx -> user_medal_fixture(%{user: user}) end)
      {:ok, lv, _html} = live(conn, ~p"/")
      assert has_element?(lv, ~s|#medals:fl-contains("3")|)
    end
  end

  describe "GET / (public school, not logged in)" do
    setup :set_school

    test "redirects to the setup page when the school hasn't been created yet", %{conn: conn} do
      result = conn |> Map.put(:host, "invalid.org") |> get(~p"/")
      assert redirected_to(result) == ~p"/schools/new"
    end

    test "returns 404 when username as subdomain doesn't exist", %{conn: conn, school: school} do
      assert_error_sent(404, fn -> conn |> Map.put(:host, "random.#{school.custom_domain}") |> get(~p"/") end)
    end

    test "doesn't list my courses", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/")
      refute has_element?(lv, ~s|#my-courses|)
    end

    test "lists the 20 most popular courses", %{conn: conn, school: school} do
      courses = Enum.map(1..21, fn idx -> course_fixture(%{name: "Course #{idx}!", school_id: school.id}) end)

      Enum.each(courses, fn course ->
        first_course? = course == Enum.at(courses, 0)
        unless first_course?, do: course_user_fixture(%{user: user_fixture(), course: course})
      end)

      {:ok, lv, _html} = live(conn, ~p"/")
      refute has_element?(lv, ~s|#courses-list dt:fl-icontains("course 1!")|)

      Enum.each(2..21, fn idx -> assert has_element?(lv, ~s|#courses-list dt:fl-icontains("course #{idx}!")|) end)
    end

    test "doesn't show the learning days count", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/")
      refute has_element?(lv, ~s|#learning-days|)
    end

    test "doesn't show the medals count", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/")
      refute has_element?(lv, ~s|#medals|)
    end
  end

  describe "GET / (Private schools)" do
    setup do
      set_school(%{conn: build_conn()}, %{public?: false})
    end

    test "redirects to the login page when the user isn't authenticated", %{conn: conn} do
      result = get(conn, ~p"/")
      assert redirected_to(result) == ~p"/users/login"
    end

    test "don't redirect to the login page when the user is authenticated", %{conn: conn, school: school} do
      user = user_fixture()
      school_user_fixture(%{user: user, school: school})

      result = conn |> log_in_user(user) |> get(~p"/")
      assert html_response(result, 200)
    end

    test "returns 403 if a user hasn't been added to a school", %{conn: conn} do
      assert_error_sent(403, fn -> conn |> log_in_user(user_fixture()) |> get(~p"/") end)
    end

    test "returns 403 if a user doesn't have a subscription", %{conn: conn} do
      user = user_fixture()
      school_user_fixture(%{user: user, school: conn.assigns.school, approved?: false})

      assert_error_sent(403, fn -> conn |> log_in_user(user_fixture()) |> get(~p"/") end)
    end
  end
end
