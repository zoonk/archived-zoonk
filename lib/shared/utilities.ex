defmodule UneebeeWeb.Shared.Utilities do
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
end
