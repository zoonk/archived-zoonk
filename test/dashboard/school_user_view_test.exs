defmodule UneebeeWeb.DashboardSchoolUserViewLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Organizations

  alias Uneebee.Organizations

  describe "user view (non-authenticated users)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn} do
      result = get(conn, ~p"/dashboard/u/1")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "user view (school student)" do
    setup :app_setup

    test "returns 403", %{conn: conn} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/u/1") end)
    end
  end

  describe "user view (school teacher)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :teacher)
    end

    test "returns 403", %{conn: conn} do
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/u/1") end)
    end
  end

  describe "user view (school manager)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :manager)
    end

    test "returns 403 when the user is not a school user", %{conn: conn} do
      user = user_fixture()
      assert_error_sent(403, fn -> get(conn, ~p"/dashboard/u/#{user.username}") end)
    end

    test "renders the page", %{conn: conn, school: school} do
      user = user_fixture()
      school_user_fixture(%{school: school, user: user, role: :student})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/u/#{user.username}")

      assert has_element?(lv, ~s|h1 span:fl-contains("#{user.username}")|)
      assert has_element?(lv, ~s|h1 span:fl-contains("@#{user.username}")|)
      assert has_element?(lv, ~s|p:fl-contains("#{user.email}")|)
      refute has_element?(lv, ~s|span:fl-icontains("teacher")|)
      assert has_element?(lv, ~s|span:fl-icontains("student")|)
    end

    test "approves a pending user", %{conn: conn, school: school} do
      user = user_fixture()
      school_user_fixture(%{school: school, user: user, approved?: false})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/u/#{user.username}")

      refute has_element?(lv, ~s|button *:fl-icontains("remove")|)
      assert lv |> element("button", "Approve") |> render_click() =~ "User approved!"
      assert has_element?(lv, ~s|button *:fl-icontains("remove")|)
    end

    test "rejects a pending user", %{conn: conn, school: school} do
      user = user_fixture()
      school_user_fixture(%{school: school, user: user, approved?: false})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/u/#{user.username}")

      refute has_element?(lv, ~s|button *:fl-icontains("remove")|)

      {:ok, _updated_lv, html} =
        lv
        |> element("button", "Reject")
        |> render_click()
        |> follow_redirect(conn, ~p"/dashboard/users")

      assert html =~ "User rejected!"
      refute Organizations.get_school_user(school.slug, user.username)
    end

    test "removes a user", %{conn: conn, school: school} do
      user = user_fixture()
      school_user_fixture(%{school: school, user: user})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/u/#{user.username}")

      {:ok, _updated_lv, _html} =
        lv
        |> element("button", "Remove")
        |> render_click()
        |> follow_redirect(conn, ~p"/dashboard/users")

      refute Organizations.get_school_user(school.slug, user.username)
    end

    test "toggles analytics for a user", %{conn: conn, school: school} do
      user = user_fixture()
      school_user_fixture(%{school: school, user: user})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/u/#{user.username}")

      lv |> element("button", "Disable analytics") |> render_click()
      refute Organizations.get_school_user(school.slug, user.username).analytics?

      lv |> element("button", "Enable analytics") |> render_click()
      assert Organizations.get_school_user(school.slug, user.username).analytics?
    end

    test "hides the analytics toggle if the school has a parent school", %{conn: conn, school: school} do
      parent_school = school_fixture(%{name: "Parent School"})
      Organizations.update_school(school, %{school_id: parent_school.id})

      user = user_fixture()
      school_user_fixture(%{school: school, user: user})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/u/#{user.username}")

      refute has_element?(lv, ~s|button *:fl-icontains("disable analytics")|)
      refute has_element?(lv, ~s|button *:fl-icontains("enable analytics")|)
    end
  end
end
