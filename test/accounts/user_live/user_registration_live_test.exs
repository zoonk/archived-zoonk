defmodule UneebeeWeb.UserRegistrationLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Organizations

  describe "Registration page" do
    test "renders registration page", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      assert has_element?(lv, ~s|h1 span:fl-icontains("create an account")|)
      assert has_element?(lv, ~s|a[href="/users/login"]:fl-icontains("sign in")|)
    end

    test "redirects if already logged in", %{conn: conn} do
      result =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/users/register")
        |> follow_redirect(conn, "/")

      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result =
        lv
        |> element("#registration_form")
        |> render_change(user: %{"email" => "with spaces", "password" => "short"})

      assert result =~ "must have the @ sign and no spaces"
      assert result =~ "should be at least 8 character"
    end
  end

  describe "register user" do
    test "use the browser's language", %{conn: conn} do
      conn = put_req_header(conn, "accept-language", "pt-BR")

      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Criar uma conta"
      assert html =~ ~s'<html lang="pt"'
    end

    test "creates account and logs the user in", %{conn: conn} do
      school_fixture()

      {:ok, lv, _html} = live(conn, ~p"/users/register")

      email = unique_user_email()
      form = form(lv, "#registration_form", user: valid_user_attributes(email: email))
      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      response = html_response(get(conn, "/"), 200)
      assert response =~ email
    end

    test "renders errors", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      existing_user = user_fixture()

      assert_field_error(lv, "email", "", "can't be blank")
      assert_field_error(lv, "email", "marieatgmail.com", "must have the @ sign and no spaces")
      assert_field_error(lv, "email", "marie@gmail .com", "must have the @ sign and no spaces")
      assert_field_error(lv, "email", existing_user.email, "has already been taken")

      assert_field_error(lv, "username", "", "can't be blank")
      assert_field_error(lv, "username", "ab", "should be at least 3 character(s)")
      assert_field_error(lv, "username", existing_user.username, "has already been taken")

      assert_field_error(lv, "password", "", "can't be blank")
      assert_field_error(lv, "password", "1@Aa", "should be at least 8 character(s)")
      assert_field_error(lv, "password", "aaaaa1@aa", "at least one upper case character")
      assert_field_error(lv, "password", "AAAAA1@AA", "at least one lower case character")
      assert_field_error(lv, "password", "aaaaAaaa", "at least one digit or punctuation character")
    end
  end

  describe "registration navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      {:ok, _login_live, _login_html} =
        lv
        |> element(~s|main a:fl-contains("Sign in")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/users/login")
    end
  end

  defp assert_field_error(lv, field, value, message) do
    lv |> element("#registration_form") |> render_change(user: %{field => value})
    assert has_element?(lv, ~s|div[phx-feedback-for="user[#{field}]"] p:fl-icontains("#{message}")|)
  end
end
