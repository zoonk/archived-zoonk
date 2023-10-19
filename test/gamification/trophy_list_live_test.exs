defmodule UneebeeWeb.TrophyListLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Content
  import Uneebee.Fixtures.Gamification

  describe "trophies list (not authenticated)" do
    test "redirects to the login page", %{conn: conn} do
      result = get(conn, ~p"/trophies")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "trophies list (student)" do
    setup :app_setup

    test "renders all earned trophies", %{conn: conn, user: user} do
      course = course_fixture(%{name: "Test course"})

      user_mission_fixture(%{user: user, reason: :profile_name})
      user_trophy_fixture(%{user: user, reason: :course_completed, course: course})

      {:ok, lv, _html} = live(conn, ~p"/trophies")

      assert has_element?(lv, ~s|dt:fl-icontains("mission completed")|)
      assert has_element?(lv, ~s|dt:fl-icontains("course completed")|)

      assert has_element?(lv, ~s|dd:fl-contains("#{course.name}")|)
      assert has_element?(lv, ~s|dd:fl-contains("You added your name to your profile.")|)
    end
  end
end
