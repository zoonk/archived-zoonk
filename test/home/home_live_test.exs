defmodule UneebeeWeb.HomeLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Organizations

  describe "home page (not authenticated)" do
    setup :set_school

    test "renders the page", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/")

      assert has_element?(lv, ~s|a span:fl-icontains("sign in")|)
      assert has_element?(lv, ~s|li[aria-current="page"] a span:fl-icontains("home")|)
    end
  end

  describe "home page (authenticated)" do
    setup :app_setup

    test "redirects to the setup page when school isn't configured", %{conn: conn} do
      result = conn |> Map.put(:host, "invalid.org") |> get(~p"/")
      assert redirected_to(result) == ~p"/schools/new"
    end

    test "renders the page", %{conn: conn} do
      school_fixture()

      {:ok, lv, _html} = live(conn, ~p"/")

      refute has_element?(lv, ~s|a span:fl-icontains("sign in")|)
      assert has_element?(lv, ~s|li[aria-current="page"] a span:fl-icontains("home")|)
    end
  end
end
