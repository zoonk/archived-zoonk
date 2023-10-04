defmodule Uneebee.Accounts.UserUtils do
  @moduledoc """
  This module contains functions that are used to manipulate user data.
  """
  alias Uneebee.Accounts.User

  @doc """
  Get the user's full name.

  ## Examples

      iex> UserUtils.full_name(%User{first_name: "John", last_name: "Doe"})
      "John Doe"

      iex> UserUtils.full_name(%User{first_name: "John"})
      "John"

      iex> UserUtils.full_name(%User{username: "johndoe"})
      "johndoe"
  """
  @spec full_name(User.t()) :: String.t()
  def full_name(%User{first_name: nil, last_name: nil, username: username}), do: username
  def full_name(%User{first_name: first_name, last_name: nil}), do: first_name
  def full_name(%User{first_name: nil, last_name: last_name}), do: last_name
  def full_name(%User{first_name: first_name, last_name: last_name}), do: "#{first_name} #{last_name}"
end
