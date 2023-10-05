defmodule UneebeeWeb.UserSettingsLiveTest do
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Gamification

  alias Uneebee.Accounts
  alias Uneebee.Gamification

  @settings_form "#settings-form"
  @email_form "#email-form"
  @password_form "#password-form"

  describe "/users/settings (not authenticated)" do
    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/users/settings/language")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/login"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "/users/settings/username" do
    setup :register_and_log_in_user

    test "updates the user username", %{conn: conn, user: user} do
      existing_user = user_fixture()
      new_username = unique_user_username()

      {:ok, lv, _html} = live(conn, ~p"/users/settings/username")

      refute has_element?(lv, ~s|#{@email_form}|)
      refute has_element?(lv, ~s|#{@password_form}|)
      assert has_element?(lv, ~s|input[name="user[username]"][value="#{user.username}"]|)

      assert field_change(lv, %{username: ""}) =~ "can&#39;t be blank"
      assert field_change(lv, %{username: "ab"}) =~ "should be at least 3 character(s)"
      assert field_change(lv, %{username: existing_user.username}) =~ "has already been taken"

      assert lv
             |> form(@settings_form, user: %{username: new_username})
             |> render_submit() =~ "Settings updated successfully"

      assert Accounts.get_user!(user.id).username == new_username
    end
  end

  describe "/users/settings/language" do
    setup :register_and_log_in_user

    test "updates the user language", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/language")

      assert has_element?(lv, ~s|option[value="en"][selected]|)
      assert lv |> form(@settings_form, user: %{language: "pt"}) |> render_submit() =~ "Configurações atualizadas"
      assert has_element?(lv, ~s|button:fl-icontains("Salvar")|)
      assert has_element?(lv, ~s|option[value="pt"][selected]|)
      assert Accounts.get_user!(user.id).language == :pt
    end
  end

  describe "/users/settings/name" do
    setup :register_and_log_in_user

    test "updates the user name", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/name")

      new_first_name = "New first name"
      new_last_name = "New last name"

      assert has_element?(lv, ~s|input[name="user[first_name]"][value="#{user.first_name}"]|)
      assert has_element?(lv, ~s|input[name="user[last_name]"][value="#{user.last_name}"]|)

      assert lv
             |> form(@settings_form, user: %{first_name: new_first_name, last_name: new_last_name})
             |> render_submit() =~ "Settings updated successfully"

      user = Accounts.get_user!(user.id)

      assert user.first_name == new_first_name
      assert user.last_name == new_last_name
    end

    test "completes a mission when the first name is added", %{conn: conn, user: user} do
      Accounts.update_user_settings(user, %{first_name: nil, last_name: nil})

      assert Gamification.get_user_mission(:profile_name, user.id) == nil

      {:ok, lv, _html} = live(conn, ~p"/users/settings/name")

      new_first_name = "New first name"

      assert lv
             |> form(@settings_form, user: %{first_name: new_first_name, last_name: nil})
             |> render_submit() =~ "Settings updated successfully"

      assert Gamification.get_user_mission(:profile_name, user.id) != nil
    end

    test "completes a mission when the last name is added", %{conn: conn, user: user} do
      Accounts.update_user_settings(user, %{first_name: nil, last_name: nil})

      assert Gamification.get_user_mission(:profile_name, user.id) == nil

      {:ok, lv, _html} = live(conn, ~p"/users/settings/name")

      new_last_name = "New last name"

      assert lv
             |> form(@settings_form, user: %{first_name: nil, last_name: new_last_name})
             |> render_submit() =~ "Settings updated successfully"

      assert Gamification.get_user_mission(:profile_name, user.id) != nil
    end

    test "removes a mission if both the first and last name are removed", %{conn: conn, user: user} do
      user_mission_fixture(%{user: user, reason: :profile_name})

      {:ok, lv, _html} = live(conn, ~p"/users/settings/name")

      assert lv
             |> form(@settings_form, user: %{first_name: nil, last_name: nil})
             |> render_submit() =~ "Settings updated successfully"

      assert Gamification.get_user_mission(:profile_name, user.id) == nil
    end
  end

  describe "/users/settings/email" do
    setup :register_and_log_in_user

    test "updates the user email", %{conn: conn, password: password, user: user} do
      new_email = unique_user_email()

      {:ok, lv, _html} = live(conn, ~p"/users/settings/email")

      refute has_element?(lv, @settings_form)
      refute has_element?(lv, @password_form)

      result =
        lv
        |> form(@email_form, %{"current_password" => password, "user" => %{"email" => new_email}})
        |> render_submit()

      assert result =~ "A link to confirm your email"
      assert Accounts.get_user_by_email(user.email)
    end

    test "renders errors with invalid data (phx-change)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/email")

      result =
        lv
        |> element(@email_form)
        |> render_change(%{
          "action" => "update_email",
          "current_password" => "invalid",
          "user" => %{"email" => "with spaces"}
        })

      assert result =~ "Change Email"
      assert result =~ "must have the @ sign and no spaces"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/email")

      result =
        lv
        |> form(@email_form, %{"current_password" => "invalid", "user" => %{"email" => user.email}})
        |> render_submit()

      assert result =~ "Change Email"
      assert result =~ "did not change"
      assert result =~ "is invalid"
    end
  end

  describe "/users/settings/password" do
    setup :register_and_log_in_user

    test "updates the user password", %{conn: conn, user: user, password: password} do
      new_password = valid_user_password()

      {:ok, lv, _html} = live(conn, ~p"/users/settings/password")

      refute has_element?(lv, @settings_form)
      refute has_element?(lv, @email_form)

      form =
        form(lv, @password_form, %{
          "current_password" => password,
          "user" => %{"email" => user.email, "password" => new_password, "password_confirmation" => new_password}
        })

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
        |> element(@password_form)
        |> render_change(%{
          "current_password" => "invalid",
          "user" => %{"password" => "short", "password_confirmation" => "does not match"}
        })

      assert result =~ "Change Password"
      assert result =~ "at least one digit or punctuation character"
      assert result =~ "at least one upper case character"
      assert result =~ "should be at least 8 character(s)"
      assert result =~ "does not match password"
    end

    test "renders errors with invalid data (phx-submit)", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/settings/password")

      result =
        lv
        |> form(@password_form, %{
          "current_password" => "invalid",
          "user" => %{"password" => "short", "password_confirmation" => "does not match"}
        })
        |> render_submit()

      assert result =~ "Change Password"
      assert result =~ "at least one digit or punctuation character"
      assert result =~ "at least one upper case character"
      assert result =~ "should be at least 8 character(s)"
      assert result =~ "does not match password"
      assert result =~ "is invalid"
    end
  end

  describe "confirm email" do
    setup %{conn: conn} do
      user = user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

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

  defp field_change(lv, changes) do
    lv |> element(@settings_form) |> render_change(user: changes)
  end
end
