defmodule Seed do
  alias ZoonkWeb.Shared.Utilities

  # Generate multiple items. This is ideal for testing infinite scroll.
  def multiple?(args) do
    args
    |> Enum.find(fn arg -> String.starts_with?(arg, "--multiple") end)
    |> get_multiple_arg()
    |> String.split("=")
    |> List.last()
    |> Utilities.string_to_boolean()
  end

  defp get_multiple_arg(nil), do: "false"
  defp get_multiple_arg(multiple), do: multiple
end
