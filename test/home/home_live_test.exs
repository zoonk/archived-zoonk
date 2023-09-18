defmodule UneebeeWeb.HomeLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "home page (not authenticated)" do
    test "renders the page", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/")

      assert has_element?(lv, ~s|a span:fl-icontains("sign in")|)
      assert has_element?(lv, ~s|li[aria-current="page"] a span:fl-icontains("home")|)
    end
  end

  describe "home page (authenticated)" do
    setup :register_and_log_in_user

    test "renders the page", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/")

      refute has_element?(lv, ~s|a span:fl-icontains("sign in")|)
      assert has_element?(lv, ~s|li[aria-current="page"] a span:fl-icontains("home")|)
    end
  end
end
