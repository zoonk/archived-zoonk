defmodule UneebeeWeb.SchoolTeacherListLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Organizations

  describe "/dashboard/teachers (non-authenticated users)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn} do
      result = get(conn, ~p"/dashboard/teachers")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "/dashboard/teachers (students)" do
    setup :app_setup

    test "returns a 403 error", %{conn: conn} do
      assert_error_sent 403, fn -> get(conn, ~p"/dashboard/teachers") end
    end
  end

  describe "/dashboard/teachers (teachers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :teacher)
    end

    test "returns a 403 error", %{conn: conn} do
      assert_error_sent 403, fn -> get(conn, ~p"/dashboard/teachers") end
    end
  end

  describe "/dashboard/teachers (managers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :manager)
    end

    test "list all teachers", %{conn: conn, school: school} do
      user1 = user_fixture(%{first_name: "User 1"})
      user2 = user_fixture(%{first_name: "User 2"})
      user3 = user_fixture(%{first_name: "User 3"})
      user4 = user_fixture(%{first_name: "User 4"})

      school_user_fixture(%{school: school, user: user1, role: :teacher})
      school_user_fixture(%{school: school, user: user2, role: :teacher, approved?: false})
      school_user_fixture(%{school: school, user: user3, role: :manager})
      school_user_fixture(%{school: school, user: user4})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/teachers")

      assert has_element?(lv, ~s|dt span:fl-icontains("#{user1.first_name}")|)
      assert has_element?(lv, ~s|dt span:fl-icontains("#{user2.first_name}")|)
      refute has_element?(lv, ~s|dt span:fl-icontains("#{user3.first_name}")|)
      refute has_element?(lv, ~s|dt span:fl-icontains("#{user4.first_name}")|)

      assert has_element?(lv, ~s|#user-#{user2.id} span[role="status"]:fl-icontains("pending")|)
      refute has_element?(lv, ~s|#user-#{user1.id} span[role="status"]:fl-icontains("pending")|)
    end

    test "approves a pending user", %{conn: conn, school: school} do
      pending_user = user_fixture(%{first_name: "Pending User"})
      school_user_fixture(%{school: school, user: pending_user, role: :teacher, approved?: false})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/teachers")

      {:ok, updated_lv, html} =
        lv
        |> element(approve_button_el())
        |> render_click()
        |> follow_redirect(conn, ~p"/dashboard/teachers")

      assert html =~ "User approved!"
      refute has_element?(updated_lv, ~s|span[role="status"]:fl-icontains("pending")|)
    end

    test "rejects a pending user", %{conn: conn, school: school} do
      pending_user = user_fixture(%{first_name: "Pending User"})
      school_user_fixture(%{school: school, user: pending_user, role: :teacher, approved?: false})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/teachers")

      {:ok, updated_lv, html} =
        lv
        |> element(reject_button_el())
        |> render_click()
        |> follow_redirect(conn, ~p"/dashboard/teachers")

      assert html =~ "User rejected!"
      refute has_element?(updated_lv, ~s|span[role="status"]:fl-icontains("pending")|)
    end

    test "adds a user using their email address", %{conn: conn} do
      user = user_fixture(%{first_name: "Albert", email: "alb@example.com"})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/teachers")

      refute has_element?(lv, ~s|dt span:fl-icontains("#{user.first_name}")|)

      {:ok, updated_lv, _html} =
        lv
        |> form("#add-user-form", %{email_or_username: user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/dashboard/teachers")

      assert has_element?(updated_lv, ~s|dt span:fl-icontains("#{user.first_name}")|)
    end

    test "adds a user using their username", %{conn: conn} do
      user = user_fixture(%{first_name: "Albert", username: "albert"})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/teachers")

      refute has_element?(lv, ~s|dt span:fl-icontains("#{user.first_name}")|)

      {:ok, updated_lv, _html} =
        lv
        |> form("#add-user-form", %{email_or_username: user.username})
        |> render_submit()
        |> follow_redirect(conn, ~p"/dashboard/teachers")

      assert has_element?(updated_lv, ~s|dt span:fl-icontains("#{user.first_name}")|)
    end

    test "displays an error when trying to add an unexisting user", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard/teachers")

      result = lv |> form("#add-user-form", %{email_or_username: "unexisting"}) |> render_submit()

      assert result =~ "User not found!"
    end
  end

  defp approve_button_el, do: ~s|button[phx-click="approve"]|
  defp reject_button_el, do: ~s|button[phx-click="reject"]|
end
