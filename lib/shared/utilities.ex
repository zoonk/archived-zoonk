defmodule Zoonk.Shared.Utilities do
  @moduledoc """
  Shared utilities for common use cases.
  """

  @doc """
  Convert a string into a boolean.

  ## Examples

      iex> string_to_boolean("true")
      true

      iex> string_to_boolean("false")
      false

      iex> string_to_boolean("anything else")
      true
  """
  @spec string_to_boolean(String.t()) :: boolean()
  def string_to_boolean("true"), do: true
  def string_to_boolean("false"), do: false
  def string_to_boolean(_str), do: true

  @doc """
  Generates a random password.

  It generates a random password that meets the following criteria:

      * At least 8 characters long
      * At least one uppercase letter
      * At least one lowercase letter
      * At least one number

  ## Examples

      iex> random_password()
      "HelloWorld123"

  """
  @spec generate_password(non_neg_integer()) :: String.t()
  def generate_password(length \\ 8) do
    # This string is appended to the password to meet the criteria
    criteria = "Zk1"

    # Adjusting the base length to account for the appended string
    base_length = max(length - String.length(criteria), 0)

    base_length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> String.slice(0, base_length)
    |> Kernel.<>(criteria)
  end

  @doc """
  Rounds a currency when the decimal is 0.
  """
  @spec round_currency(float()) :: String.t()
  def round_currency(currency) when currency == round(currency), do: currency |> round() |> Integer.to_string()
  def round_currency(currency), do: :erlang.float_to_binary(currency, decimals: 2)
end
