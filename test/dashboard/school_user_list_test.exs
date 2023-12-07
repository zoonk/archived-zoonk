defmodule UneebeeWeb.SchoolUserListLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Organizations

  describe "/dashboard/users (non-authenticated users)" do
    setup :set_school

    test "redirects to the login page", %{conn: conn} do
      result = get(conn, ~p"/dashboard/users")
      assert redirected_to(result) == ~p"/users/login"
    end
  end

  describe "/dashboard/users (students)" do
    setup :app_setup

    test "returns a 403 error", %{conn: conn} do
      assert_error_sent 403, fn -> get(conn, ~p"/dashboard/users") end
    end
  end

  describe "/dashboard/users (teachers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :teacher)
    end

    test "returns a 403 error", %{conn: conn} do
      assert_error_sent 403, fn -> get(conn, ~p"/dashboard/users") end
    end
  end

  describe "/dashboard/users (managers)" do
    setup do
      app_setup(%{conn: build_conn()}, school_user: :manager)
    end

    test "list all users", %{conn: conn, school: school} do
      user1 = user_fixture(%{first_name: "User 1"})
      user2 = user_fixture(%{first_name: "User 2"})
      user3 = user_fixture(%{first_name: "User 3"})
      user4 = user_fixture(%{first_name: "User 4"})

      school_user_fixture(%{school: school, user: user1, role: :manager})
      school_user_fixture(%{school: school, user: user2, role: :manager, approved?: false})
      school_user_fixture(%{school: school, user: user3, role: :teacher})
      school_user_fixture(%{school: school, user: user4})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/users")

      assert has_element?(lv, ~s|h3:fl-icontains("#{user1.first_name}")|)
      assert has_element?(lv, ~s|#user-#{user1.id} *:fl-icontains("manager")|)

      assert has_element?(lv, ~s|h3:fl-icontains("#{user2.first_name}")|)
      assert has_element?(lv, ~s|#user-#{user2.id} *:fl-icontains("pending")|)

      assert has_element?(lv, ~s|h3:fl-icontains("#{user3.first_name}")|)
      assert has_element?(lv, ~s|#user-#{user3.id} *:fl-icontains("teacher")|)

      assert has_element?(lv, ~s|h3:fl-icontains("#{user4.first_name}")|)
      assert has_element?(lv, ~s|#user-#{user4.id} *:fl-icontains("student")|)
    end

    test "adds a user using their email address", %{conn: conn} do
      user = user_fixture(%{first_name: "Albert", email: "alb@example.com"})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/users")

      refute has_element?(lv, ~s|h3:fl-icontains("#{user.first_name}")|)

      {:ok, updated_lv, _html} =
        lv
        |> form("#add-user-form", %{email_or_username: user.email})
        |> render_submit()
        |> follow_redirect(conn, ~p"/dashboard/users")

      assert has_element?(updated_lv, ~s|h3:fl-icontains("#{user.first_name}")|)
    end

    test "adds a user using their username", %{conn: conn} do
      user = user_fixture(%{first_name: "Albert", username: "albert"})

      {:ok, lv, _html} = live(conn, ~p"/dashboard/users")

      refute has_element?(lv, ~s|h3:fl-icontains("#{user.first_name}")|)

      {:ok, updated_lv, _html} =
        lv
        |> form("#add-user-form", %{email_or_username: user.username})
        |> render_submit()
        |> follow_redirect(conn, ~p"/dashboard/users")

      assert has_element?(updated_lv, ~s|h3:fl-icontains("#{user.first_name}")|)
    end

    test "displays an error when trying to add an unexisting user", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/dashboard/users")

      result =
        lv
        |> form("#add-user-form", %{email_or_username: "unexisting"})
        |> render_submit()

      assert result =~ "User not found!"
    end
  end
end
