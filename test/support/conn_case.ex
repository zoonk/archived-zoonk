defmodule UneebeeWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use UneebeeWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  import Uneebee.Fixtures.Accounts

  alias Plug.Conn
  alias Uneebee.Accounts.User

  using do
    quote do
      use UneebeeWeb, :verified_routes

      import Phoenix.ConnTest

      # Import conveniences for testing with connections
      import Plug.Conn
      import UneebeeWeb.ConnCase

      # The default endpoint for testing
      @endpoint UneebeeWeb.Endpoint
    end
  end

  setup tags do
    Uneebee.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  @spec register_and_log_in_user(%{conn: Conn.t()}) :: %{conn: Conn.t(), user: User.t(), password: String.t()}
  def register_and_log_in_user(%{conn: conn}) do
    attrs = valid_user_attributes()
    user = user_fixture(attrs)
    %{conn: log_in_user(conn, user), user: user, password: attrs.password}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  @spec log_in_user(Conn.t(), User.t()) :: Conn.t()
  def log_in_user(conn, user) do
    token = Uneebee.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Conn.put_session(:user_token, token)
  end
end
