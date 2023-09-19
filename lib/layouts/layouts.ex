defmodule UneebeeWeb.Layouts do
  @moduledoc false
  use UneebeeWeb, :html

  embed_templates "templates/*"

  @spec user_settings?(atom()) :: boolean()
  def user_settings?(active_page) do
    active_page |> Atom.to_string() |> String.starts_with?("user_settings")
  end
end
