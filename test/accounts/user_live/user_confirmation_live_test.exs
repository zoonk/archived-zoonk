defmodule UneebeeWeb.UserConfirmationLiveTest do
  @moduledoc false
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Uneebee.Fixtures.Accounts

  alias Uneebee.Accounts
  alias Uneebee.Repo

  setup :set_school

  describe "Confirm user" do
    test "renders confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/confirm/some-token")
      assert html =~ "Confirm Account"
    end

    test "use the user's language as the default value", %{conn: conn} do
      {:ok, _lv, html} = conn |> log_in_user(user_fixture(language: :pt)) |> live(~p"/users/confirm/some-token")
      assert html =~ "Confirmar minha conta"
    end

    test "use the browser's language when the user is not logged in", %{conn: conn} do
      conn = put_req_header(conn, "accept-language", "pt-BR")
      {:ok, _lv, html} = live(conn, ~p"/users/confirm/some-token")
      assert html =~ "Confirmar minha conta"
    end

    test "confirms the given token once", %{conn: conn} do
      user = user_fixture()
      token = extract_user_token(fn url -> Accounts.deliver_user_confirmation_instructions(user, nil, url) end)

      {:ok, lv, _html} = live(conn, ~p"/users/confirm/#{token}")

      result =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = result

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "User confirmed successfully"
      assert Accounts.get_user!(user.id).confirmed_at
      refute get_session(conn, :user_token)
      assert Repo.all(Accounts.UserToken) == []

      # when not logged in
      {:ok, invalid_lv, _html} = live(conn, ~p"/users/confirm/#{token}")

      invalid_result =
        invalid_lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, "/")

      assert {:ok, conn} = invalid_result

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "User confirmation link is invalid or it has expired"
    end

    test "does not confirm email with invalid token", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/users/confirm/invalid-token")

      {:ok, conn} =
        lv
        |> form("#confirmation_form")
        |> render_submit()
        |> follow_redirect(conn, ~p"/")

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "User confirmation link is invalid or it has expired"
      refute Accounts.get_user!(user.id).confirmed_at
    end
  end
end
