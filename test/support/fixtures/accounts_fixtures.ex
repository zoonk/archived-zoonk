defmodule Uneebee.Fixtures.Accounts do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Uneebee.Accounts` context.
  """

  alias Uneebee.Accounts.User

  @spec unique_user_email() :: String.t()
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  @spec valid_user_password() :: String.t()
  def valid_user_password, do: "HelloWorld!123"

  @spec unique_user_username() :: String.t()
  def unique_user_username, do: "user#{System.unique_integer()}"

  @spec valid_user_attributes(map()) :: map()
  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password(),
      username: unique_user_username()
    })
  end

  @spec user_fixture(map()) :: User.t()
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Uneebee.Accounts.register_user()

    user
  end

  @spec extract_user_token(fun()) :: String.t()
  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
