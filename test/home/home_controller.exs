defmodule UneebeeWeb.HomeControllerTest do
  @moduledoc false
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Content

  alias Uneebee.Gamification.MissionUtils

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

    test "redirects to the course list when a user never completed a lesson", %{conn: conn} do
      result = get(conn, ~p"/")
      assert redirected_to(result) == ~p"/courses"
    end

    test "redirects to the course view when a user completed a lesson", %{conn: conn, user: user} do
      course = course_fixture()
      generate_user_lesson(user, 0, course: course)

      result = conn(get(~p"/"))
      assert redirected_to(result) == ~p"/c/#{course.slug}"
    end
  end
end
