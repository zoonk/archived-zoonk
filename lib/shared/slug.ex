defmodule Zoonk.Shared.Slug do
  @moduledoc """
  Slug module for generating slugs.

  Forked from https://github.com/norbajunior/slugy
  """

  @doc """
  Generate a slug from a string.
  """
  @spec slug(String.t()) :: String.t()
  def slug(str) do
    str
    |> String.trim()
    |> String.normalize(:nfd)
    |> String.replace(~r/\s\s+/, " ")
    |> String.replace(~r/[^A-z\s\d-]/u, "")
    |> String.replace(~r/\s/, "-")
    |> String.replace(~r/--+/, "-")
    |> String.downcase()
  end
end
