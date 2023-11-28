defmodule Seed do
  def get_kind(args) do
    args
    |> Enum.find(fn arg -> String.starts_with?(arg, "--kind=") end)
    |> get_kind_arg()
    |> String.split("=")
    |> List.last()
    |> String.to_atom()
  end

  defp get_kind_arg(nil), do: "white_label"
  defp get_kind_arg(kind), do: kind
end
