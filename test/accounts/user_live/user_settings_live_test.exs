defmodule ZoonkWeb.UserSettingsLiveTest do
  use ZoonkWeb.ConnCase, async: true

  import Mox
  import Phoenix.LiveViewTest
  import Zoonk.Fixtures.Accounts
  import Zoonk.Fixtures.Organizations

  alias Zoonk.Accounts
  alias Zoonk.Organizations
  alias Zoonk.Repo
  alias Zoonk.Storage.SchoolObject

  @form "#settings-form"

  setup :verify_on_exit!

  describe "/users/settings (not authenticated)" do
    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/users/settings")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/login"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "/users/settings (username)" do
    setup :register_and_log_in_user

    test "updates the user username", %{conn: conn, user: user} do
      existing_user = user_fixture()
      new_username = unique_user_username()

      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("settings")|)
      assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("profile")|)

      assert has_element?(lv, ~s|input[name="user[username]"][value="#{user.username}"]|)

      assert field_change(lv, %{username: ""}) =~ "can&#39;t be blank"
      assert field_change(lv, %{username: "ab"}) =~ "should be at least 3 character(s)"
      assert field_change(lv, %{username: existing_user.username}) =~ "has already been taken"

      assert {:ok, _lv, html} =
               lv
               |> form(@form, user: %{username: new_username})
               |> render_submit()
               |> follow_redirect(conn, ~p"/users/settings")

      assert html =~ "Settings updated successfully"

      assert Accounts.get_user!(user.id).username == new_username
    end
  end

  describe "/users/settings (language)" do
    setup :register_and_log_in_user

    test "updates the user language", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("settings")|)
      assert has_element?(lv, ~s|li[aria-current="page"] a:fl-icontains("profile")|)

      assert has_element?(lv, ~s|option[value="en"][selected]|)

      assert {:ok, updated_lv, html} =
               lv
               |> form(@form, user: %{language: "pt"})
               |> render_submit()
               |> follow_redirect(conn, ~p"/users/settings")

      assert html =~ "Configurações atualizadas"
      assert has_element?(updated_lv, ~s|button *:fl-icontains("Salvar")|)
      assert has_element?(updated_lv, ~s|option[value="pt"][selected]|)
      assert Accounts.get_user!(user.id).language == :pt
    end
  end

  describe "/users/settings (name)" do
    setup :register_and_log_in_user

    test "updates the user name", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("settings")|)
      assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("profile")|)

      new_first_name = "New first name"
      new_last_name = "New last name"

      assert has_element?(lv, ~s|input[name="user[first_name]"][value="#{user.first_name}"]|)
      assert has_element?(lv, ~s|input[name="user[last_name]"][value="#{user.last_name}"]|)

      assert {:ok, _updated_lv, html} =
               lv
               |> form(@form, user: %{first_name: new_first_name, last_name: new_last_name})
               |> render_submit()
               |> follow_redirect(conn, ~p"/users/settings")

      assert html =~ "Settings updated successfully"

      user = Accounts.get_user!(user.id)

      assert user.first_name == new_first_name
      assert user.last_name == new_last_name
    end

    test "makes sure the first name doesn't get replaced when filling the last name", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      new_first_name = "New first name"
      new_last_name = "New last name"

      assert has_element?(lv, ~s|input[name="user[first_name]"][value="#{user.first_name}"]|)
      assert has_element?(lv, ~s|input[name="user[last_name]"][value="#{user.last_name}"]|)

      lv |> element(@form) |> render_change(%{user: %{first_name: new_first_name}})

      assert has_element?(lv, ~s|input[name="user[first_name]"][value="#{new_first_name}"]|)
      assert has_element?(lv, ~s|input[name="user[last_name]"][value="#{user.last_name}"]|)

      lv |> element(@form) |> render_change(%{user: %{last_name: new_last_name}})

      assert has_element?(lv, ~s|input[name="user[first_name]"][value="#{new_first_name}"]|)
      assert has_element?(lv, ~s|input[name="user[last_name]"][value="#{new_last_name}"]|)
    end
  end

  describe "/users/settings/avatar" do
    setup :app_setup
  end

  describe "/users/settings/email" do
    setup :register_and_log_in_user

    test "updates the user email", %{conn: conn, password: password, user: user} do
      new_email = unique_user_email()

      {:ok, lv, _html} = live(conn, ~p"/users/settings/email")

      assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("settings")|)
      assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("email")|)

      result =
        lv
        |> form(@form, %{"current_password" => password, "user" => %{"email" => new_email}})
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_user_by_email(user.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/email")

      result =
        lv
        |> element(@form)
        |> render_change(%{"action" => "update_email", "current_password" => "invalid", "user" => %{"email" => "with spaces"}})

      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/email")

      result =
        lv
        |> form(@form, %{"current_password" => "invalid", "user" => %{"email" => user.email}})
        |> render_submit()

      assert result =~ "did not change"
    end
  end

  describe "/users/setting/email (guest user)" do
    setup :set_school_with_guest_user

    test "converts a guest account into a real account", %{conn: conn} do
      attrs = valid_user_attributes()

      {:ok, lv, _html} = live(conn, ~p"/users/settings")

      refute has_element?(lv, "li", "Profile")
      refute has_element?(lv, "li", "Avatar")
      refute has_element?(lv, "li", "Email")
      refute has_element?(lv, "li", "Password")
      refute has_element?(lv, "li", "Logout")
      assert has_element?(lv, "li[aria-current=page]", "Setup")

      result =
        lv
        |> form(@form, %{"user" => attrs})
        |> render_submit()

      assert result =~ "A link to confirm your email"
    end
  end

  describe "/users/settings/password" do
    setup :register_and_log_in_user

    test "updates the user password", %{conn: conn, user: user, password: password} do
      new_password = valid_user_password()

      {:ok, lv, _html} = live(conn, ~p"/users/settings/password")

      assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("settings")|)
      assert has_element?(lv, ~s|li[aria-current=page] a:fl-icontains("password")|)

      form =
        form(lv, @form, %{"current_password" => password, "user" => %{"email" => user.email, "password" => new_password, "password_confirmation" => new_password}})

      render_submit(form)
      new_password_conn = follow_trigger_action(form, conn)

      assert redirected_to(new_password_conn) == ~p"/users/settings/password"
      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)
      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~ "Password updated successfully"
      assert Accounts.get_user_by_email_and_password(user.email, new_password)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/password")

      result =
        lv
        |> element(@form)
        |> render_change(%{"current_password" => "invalid", "user" => %{"password" => "short", "password_confirmation" => "does not match"}})

      assert result =~ "at least one digit or punctuation character"
      assert result =~ "at least one upper case character"
      assert result =~ "should be at least 8 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/password")

      result =
        lv
        |> form(@form, %{"current_password" => "invalid", "user" => %{"password" => "short", "password_confirmation" => "does not match"}})
        |> render_submit()

      assert result =~ "at least one digit or punctuation character"
      assert result =~ "at least one upper case character"
      assert result =~ "should be at least 8 character(s)"
      assert result =~ "does not match password"
    end
  end

  describe "settings" do
    setup :app_setup

    test "displays the analytics tag", %{conn: conn, school: school} do
      {:ok, _lv, html} = live(conn, "/users/settings")

      assert html =~ "src=\"https://plausible.io/js/script.js\""
      assert html =~ "data-domain=\"#{school.custom_domain}\""
    end

    test "hides the analytics tag if the user has disabled it", %{conn: conn, school: school, user: user} do
      school_user = Organizations.get_school_user(school.slug, user.username)
      Organizations.update_school_user(school_user.id, %{analytics?: false})

      {:ok, _lv, html} = live(conn, "/users/settings")

      refute html =~ "src=\"https://plausible.io/js/script.js\""
      refute html =~ "data-domain=\"#{school.custom_domain}\""
    end

    test "displays the analytics tag from the parent school when visiting a child school", %{conn: conn, school: school, user: user} do
      child_school = school_fixture(%{school_id: school.id})
      school_user_fixture(%{school: child_school, user: user, analytics?: true})
      conn = Map.put(conn, :host, "#{child_school.slug}.#{school.custom_domain}")

      {:ok, _lv, html} = live(conn, "/users/settings")

      assert html =~ "src=\"https://plausible.io/js/script.js\""
      assert html =~ "data-domain=\"#{school.custom_domain}\""
    end

    test "displays the analytics tag from the parent school when visiting a child school using a custom domain", %{conn: conn, school: school, user: user} do
      child_school = school_fixture(%{school_id: school.id})
      school_user_fixture(%{school: child_school, user: user, analytics?: true})
      conn = Map.put(conn, :host, child_school.custom_domain)

      {:ok, _lv, html} = live(conn, "/users/settings")

      assert html =~ "src=\"https://plausible.io/js/script.js\""
      assert html =~ "data-domain=\"#{school.custom_domain}\""
    end
  end

  describe "/users/settings/delete" do
    setup :app_setup

    test "deletes the user account", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/delete")

      assert has_element?(lv, "li[aria-current=page]", "Settings")
      assert has_element?(lv, "li[aria-current=page]", "Delete")

      lv
      |> form("#delete-form", %{confirmation: "CONFIRM"})
      |> render_submit()

      assert_redirect(lv, ~p"/users/register")

      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "doesn't delete if confirmation message doesn't match", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/delete")

      assert has_element?(lv, "li[aria-current=page]", "Delete")

      result =
        lv
        |> form("#delete-form", %{confirmation: "WRONG"})
        |> render_submit()

      assert result =~ "Confirmation message does not match."

      assert Accounts.get_user!(user.id).username == user.username
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      user = user_fixture()
      email = unique_user_email()
      token = extract_user_token(fn url -> Accounts.deliver_user_update_email_instructions(%{user | email: email}, nil, user.email, url) end)

      %{conn: log_in_user(conn, user), token: token, email: email, user: user}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      {:error, redirect} = live(conn, ~p"/users/settings/confirm_email/#{token}")

      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/settings/email"
      assert %{"info" => message} = flash
      assert message == "Email changed successfully."
      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      # use confirm token again
      {:error, invalid_redirect} = live(conn, ~p"/users/settings/confirm_email/#{token}")
      assert {:live_redirect, %{to: path, flash: flash}} = invalid_redirect
      assert path == ~p"/users/settings/email"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      {:error, redirect} = live(conn, ~p"/users/settings/confirm_email/oops")
      assert {:live_redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/settings/email"
      assert %{"error" => message} = flash
      assert message == "Email change link is invalid or it has expired."
      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()

      {:error, redirect} = live(conn, ~p"/users/settings/confirm_email/#{token}")
      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/login"
      assert %{"error" => message} = flash
      assert message == "You must log in to access this page."
    end
  end

  describe "confirm email (guest user)" do
    setup %{conn: conn} do
      {:ok, user} = Accounts.create_guest_user()
      email = unique_user_email()
      token = extract_user_token(fn url -> Accounts.deliver_user_update_email_instructions(%{user | email: email}, nil, user.email, url) end)

      %{conn: log_in_user(conn, user), user: user, token: token, email: email}
    end

    test "updates the email", %{conn: conn, user: user, token: token, email: email} do
      assert user.guest?
      {:error, _redirect} = live(conn, ~p"/users/settings/confirm_email/#{token}")
      refute Accounts.get_user_by_email(email).guest?
    end
  end

  describe "confirm email (guest user, child school)" do
    setup %{conn: conn} do
      school = school_fixture(%{allow_guests?: true})
      child_school = school_fixture(%{school_id: school.id, allow_guests?: true})

      {:ok, user} = Accounts.create_guest_user()
      email = unique_user_email()
      token = extract_user_token(fn url -> Accounts.deliver_user_update_email_instructions(%{user | email: email}, nil, user.email, url) end)

      conn = conn |> log_in_user(user) |> Map.put(:host, "#{child_school.slug}.#{school.custom_domain}")

      %{conn: conn, user: user, token: token, email: email}
    end

    test "updates the email", %{conn: conn, user: user, token: token, email: email} do
      assert user.guest?
      {:error, _redirect} = live(conn, ~p"/users/settings/confirm_email/#{token}")
      refute Accounts.get_user_by_email(email).guest?
    end
  end

  defp field_change(lv, changes) do
    lv |> element(@form) |> render_change(user: changes)
  end
end
