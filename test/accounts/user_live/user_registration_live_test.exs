defmodule UneebeeWeb.UserRegistrationLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Accounts

  alias Uneebee.Accounts
  alias Uneebee.Organizations

  describe "Registration page (school not configured)" do
    test "renders registration page", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      assert has_element?(lv, ~s|h1 span:fl-icontains("create an account")|)
      assert has_element?(lv, ~s|a[href="/users/login"]:fl-icontains("sign in")|)
    end

    test "redirects if already logged in", %{conn: conn} do
      result = conn |> log_in_user(user_fixture()) |> live(~p"/users/register") |> follow_redirect(conn, "/")
      assert {:ok, _conn} = result
    end

    test "renders errors for invalid data", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      result = lv |> element("#registration_form") |> render_change(user: %{"email" => "with spaces", "password" => "short"})

      assert result =~ "must have the @ sign and no spaces"
      assert result =~ "should be at least 8 character"
    end

    test "automatically confirms a user", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      attrs = valid_user_attributes()
      lv |> form("#registration_form", user: attrs) |> render_submit()

      assert Accounts.get_user_by_email(attrs.email).confirmed_at != nil
    end
  end

  describe "register user (school configured)" do
    setup :set_school

    test "use the browser's language", %{conn: conn} do
      conn = put_req_header(conn, "accept-language", "pt-BR")

      {:ok, _lv, html} = live(conn, ~p"/users/register")

      assert html =~ "Criar uma conta"
      assert html =~ ~s'<html lang="pt"'
    end

    test "creates account and logs the user in", %{conn: conn, school: school} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      attrs = valid_user_attributes()
      form = form(lv, "#registration_form", user: attrs)
      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request
      response = html_response(get(conn, ~p"/courses"), 200)
      assert response =~ "Settings"

      # User should not be confirmed.
      assert Accounts.get_user_by_email(attrs.email).confirmed_at == nil

      # Check if the user was added as school user
      school_user = Organizations.get_school_user(school.slug, attrs.username)
      assert school_user.approved?
      assert school_user.role == :student
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

    test "displays terms of use link", %{conn: conn, school: school} do
      link = "https://example.com/terms"
      Organizations.update_school(school, %{terms_of_use: link})

      {:ok, lv, _html} = live(conn, ~p"/users/register")

      assert has_element?(lv, ~s|a[href="#{link}"]:fl-icontains("terms of use")|)
      refute has_element?(lv, ~s|a:fl-icontains("privacy policy")|)
    end

    test "displays privacy policy link", %{conn: conn, school: school} do
      link = "https://example.com/privacy"
      Organizations.update_school(school, %{privacy_policy: link})

      {:ok, lv, _html} = live(conn, ~p"/users/register")

      assert has_element?(lv, ~s|a[href="#{link}"]:fl-icontains("privacy policy")|)
      refute has_element?(lv, ~s|a:fl-icontains("terms of use")|)
    end

    test "displays terms of use and privacy policy links", %{conn: conn, school: school} do
      terms_link = "https://example.com/terms"
      privacy_link = "https://example.com/privacy"
      Organizations.update_school(school, %{terms_of_use: terms_link, privacy_policy: privacy_link})

      {:ok, lv, _html} = live(conn, ~p"/users/register")

      assert has_element?(lv, ~s|a[href="#{terms_link}"]:fl-icontains("terms of use")|)
      assert has_element?(lv, ~s|a[href="#{privacy_link}"]:fl-icontains("privacy policy")|)
    end

    test "displays neither terms of use nor privacy policy links", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      refute has_element?(lv, ~s|a:fl-icontains("terms of use")|)
      refute has_element?(lv, ~s|a:fl-icontains("privacy policy")|)
    end
  end

  describe "register user (school not configured)" do
    test "creates account and logs the user in", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/register")

      email = unique_user_email()
      form = form(lv, "#registration_form", user: valid_user_attributes(email: email))
      render_submit(form)
      conn = follow_trigger_action(form, conn)

      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the school setup redirect
      response = get(conn, ~p"/")
      assert redirected_to(response) == ~p"/schools/new"
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
