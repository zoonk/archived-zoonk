defmodule UneebeeWeb.MedalListLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Gamification

  describe "medals list (not authenticated)" do
    test "redirects to the login page", %{conn: conn} do
      result = get(conn, ~p"/medals")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "medals list (student)" do
    setup :app_setup

    test "renders all earned medals", %{conn: conn, user: user} do
      Enum.each(1..3, fn _idx -> user_medal_fixture(%{user: user, medal: :gold, reason: :perfect_lesson_first_try}) end)
      Enum.each(1..2, fn _idx -> user_medal_fixture(%{user: user, medal: :silver, reason: :perfect_lesson_practiced}) end)
      user_medal_fixture(%{user: user, medal: :bronze, reason: :mission_completed})

      {:ok, lv, _html} = live(conn, ~p"/medals")

      assert has_element?(lv, ~s|li a span:fl-icontains("Home")|)

      assert has_element?(lv, ~s|#medal-perfect_lesson_first_try dt:fl-icontains("perfect lesson")|)
      assert has_element?(lv, ~s|#medal-perfect_lesson_practiced dt:fl-icontains("perfect lesson")|)
      assert has_element?(lv, ~s|#medal-mission_completed dt:fl-icontains("mission completed")|)
      refute has_element?(lv, ~s|#medal-lesson_completed_with_errors|)

      assert has_element?(lv, ~s|#medal-perfect_lesson_first_try dd:fl-contains("3")|)
      assert has_element?(lv, ~s|#medal-perfect_lesson_practiced dd:fl-contains("2")|)
      assert has_element?(lv, ~s|#medal-mission_completed dd:fl-contains("1")|)

      assert has_element?(lv, ~s|h2:fl-icontains("3 gold medals")|)
      assert has_element?(lv, ~s|h2:fl-icontains("2 silver medals")|)
      assert has_element?(lv, ~s|h2:fl-icontains("1 bronze medal")|)
    end
  end
end
