defmodule UneebeeWeb.UserResetPasswordLiveTest do
  use UneebeeWeb.ConnCase

  import Phoenix.LiveViewTest
  import Uneebee.AccountsFixtures

  alias Uneebee.Accounts

  setup do
    user = user_fixture()

    token =
      extract_user_token(fn url ->
        Accounts.deliver_user_reset_password_instructions(user, url)
      end)

    %{token: token, user: user}
  end

  describe "Reset password page" do
    test "renders reset password with valid token", %{conn: conn, token: token} do
      {:ok, _lv, html} = live(conn, ~p"/users/reset_password/#{token}")

      assert html =~ "Reset Password"
    end

    test "does not render reset password with invalid token", %{conn: conn} do
      {:error, {:redirect, to}} = live(conn, ~p"/users/reset_password/invalid")

      assert to == %{
               flash: %{"error" => "Reset password link is invalid or it has expired."},
               to: ~p"/"
             }
    end

    test "renders errors for invalid data", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/users/reset_password/#{token}")

      result =
        lv
        |> element("#reset_password_form")
        |> render_change(user: %{"password" => "secret", "confirmation_password" => "secret123456"})

      assert result =~ "should be at least 8 character"
      assert result =~ "does not match password"
    end
  end

  describe "Reset Password" do
    test "resets password once", %{conn: conn, token: token, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/reset_password/#{token}")

      {:ok, conn} =
        lv
        |> form("#reset_password_form",
          user: %{
            "password" => "ValidPassword1",
            "password_confirmation" => "ValidPassword1"
          }
        )
        |> render_submit()
        |> follow_redirect(conn, ~p"/users/login")

      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Password reset successfully"
      assert Accounts.get_user_by_email_and_password(user.email, "ValidPassword1")
    end

    test "does not reset password on invalid data", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/users/reset_password/#{token}")

      result =
        lv
        |> form("#reset_password_form",
          user: %{
            "password" => "short",
            "password_confirmation" => "does not match"
          }
        )
        |> render_submit()

      assert result =~ "Reset Password"
      assert result =~ "should be at least 8 character(s)"
      assert result =~ "does not match password"
    end
  end

  describe "Reset password navigation" do
    test "redirects to login page when the Log in button is clicked", %{conn: conn, token: token} do
      {:ok, lv, _html} = live(conn, ~p"/users/reset_password/#{token}")

      {:ok, _conn} =
        lv
        |> element(~s|main a:fl-contains("Log in")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/users/login")
    end

    test "redirects to password reset page when the Register button is clicked", %{
      conn: conn,
      token: token
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/reset_password/#{token}")

      {:ok, conn} =
        lv
        |> element(~s|main a:fl-contains("Register")|)
        |> render_click()
        |> follow_redirect(conn, ~p"/users/register")

      assert conn.resp_body =~ "Create an account"
    end
  end
end
