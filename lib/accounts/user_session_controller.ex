defmodule UneebeeWeb.Controller.Accounts.User.Session do
  @moduledoc false
  use UneebeeWeb, :controller

  alias Uneebee.Accounts
  alias UneebeeWeb.Plugs.UserAuth

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  @spec create(Plug.Conn.t(), map(), String.t() | nil) :: Plug.Conn.t()
  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, dgettext("auth", "Account created successfully!"))
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings/password")
    |> create(params, dgettext("auth", "Password updated successfully!"))
  end

  def create(conn, params) do
    create(conn, params, nil)
  end

  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, dgettext("auth", "Invalid email or password."))
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/login")
    end
  end

  @spec delete(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def delete(conn, _params) do
    UserAuth.log_out_user(conn)
  end
end
