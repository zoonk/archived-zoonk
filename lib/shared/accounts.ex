defmodule UneebeeWeb.Shared.Accounts do
  @moduledoc """
  Shared functions for accounts.
  """
  alias Uneebee.Accounts.User

  @doc """
  Returns the avatar label for a user.

  ## Examples

      iex> get_avatar_label(%User{first_name: "John", username: "john"})
      "John"
      iex> get_avatar_label(%User{first_name: nil, username: "foo"})
      "foo"
  """
  @spec get_avatar_label(User.t()) :: String.t()
  def get_avatar_label(%User{first_name: nil, username: username}), do: username
  def get_avatar_label(%User{first_name: first_name}), do: first_name
end
