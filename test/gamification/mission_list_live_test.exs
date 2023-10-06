defmodule UneebeeWeb.MissionListLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Gamification

  describe "missions list (not authenticated)" do
    test "redirects to the login page", %{conn: conn} do
      result = get(conn, ~p"/missions")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "missions list (student)" do
    setup :app_setup

    test "renders completed and next missions", %{conn: conn, user: user} do
      user_mission_fixture(%{user: user, reason: :profile_name})

      {:ok, lv, _html} = live(conn, ~p"/missions")

      assert has_element?(lv, ~s|#completed-missions div span:fl-icontains("profile name")|)
      assert has_element?(lv, ~s|#next-missions div span:fl-icontains("first lesson")|)
    end
  end
end
