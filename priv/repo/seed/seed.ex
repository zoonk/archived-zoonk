defmodule Seed do
  alias UneebeeWeb.Shared.Utilities

  def get_kind(args) do
    args
    |> Enum.find(fn arg -> String.starts_with?(arg, "--kind=") end)
    |> get_kind_arg()
    |> String.split("=")
    |> List.last()
    |> String.to_atom()
  end

  # Generate multiple items. This is ideal for testing infinite scroll.
  def multiple?(args) do
    args
    |> Enum.find(fn arg -> String.starts_with?(arg, "--multiple") end)
    |> get_multiple_arg()
    |> String.split("=")
    |> List.last()
    |> Utilities.string_to_boolean()
  end

  defp get_kind_arg(nil), do: "white_label"
  defp get_kind_arg(kind), do: kind

  defp get_multiple_arg(nil), do: "false"
  defp get_multiple_arg(multiple), do: multiple
end
