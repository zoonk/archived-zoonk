defmodule ZoonkWeb.UserLoginLiveTest do
  use ZoonkWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Zoonk.Fixtures.Accounts
  import Zoonk.Fixtures.Organizations

  describe "Log in page" do
    test "renders log in page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/login")

      assert html =~ "Sign in to your account"
      assert html =~ "Register"
      assert html =~ "Forgot your password?"
    end

    test "redirects if already logged in", %{conn: conn} do
      result = conn |> log_in_user(user_fixture()) |> live(~p"/users/login") |> follow_redirect(conn, "/")
      assert {:ok, _conn} = result
    end

    test "displays a default logo when the school doesn't have one", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/login")
      assert has_element?(lv, ~s|img[src="/favicon/180.png"]|)
    end
  end

  describe "login page (with school configured)" do
    setup do
      set_school(%{conn: build_conn()}, %{allow_guests?: true, logo: "/m_logo.png", icon: "/m_icon.png"})
    end

    test "renders the page even when guests are allowed", %{conn: conn} do
      assert {:ok, _lv, html} = live(conn, ~p"/users/login")
      assert html =~ "Sign in to your account"
    end

    test "displays the logo and icon from the app school when it has one", %{conn: conn, school: school} do
      child_school = school_fixture(%{school_id: school.id, logo: nil})
      conn = Map.put(conn, :host, "#{child_school.slug}.#{school.custom_domain}")

      {:ok, lv, html} = live(conn, ~p"/users/login")

      assert has_element?(lv, ~s|img[src="/m_icon.png"]|)
      assert html =~ ~s(sizes="16x16" href="/m_icon.png"/>)
    end
  end

  describe "user login" do
    test "redirects if user login with valid credentials", %{conn: conn} do
      password = "ValidPassword123"
      user = user_fixture(%{password: password})

      {:ok, lv, _html} = live(conn, ~p"/users/login")

      form = form(lv, "#login_form", user: %{email_or_username: user.email, password: password, remember_me: true})
      conn = submit_form(form, conn)
      assert redirected_to(conn) == ~p"/"
    end

    test "redirects to login page with a flash error if there are no valid credentials", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/login")

      form = form(lv, "#login_form", user: %{email_or_username: "test@email.com", password: "123456", remember_me: true})
      conn = submit_form(form, conn)

      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password."
      assert redirected_to(conn) == "/users/login"
    end

    test "user authentication using username", %{conn: conn} do
      password = "ValidPassword1"
      user = user_fixture(%{password: password})

      {:ok, lv, _html} = live(conn, ~p"/users/login")

      form = form(lv, "#login_form", user: %{email_or_username: user.username, password: password, remember_me: true})
      conn = submit_form(form, conn)
      assert redirected_to(conn) == ~p"/"
    end
  end
end
