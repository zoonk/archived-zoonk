# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule UneebeeWeb.Components.Layouts.DashboardMenuItem do
  @moduledoc false
  use UneebeeWeb, :html

  attr :active, :boolean, default: false
  attr :rest, :global, include: ~w(href method navigate)

  slot :inner_block

  def dashboard_menu_item(assigns) do
    ~H"""
    <li>
      <.link class={[@active && "text-indigo-600"]} {@rest}><%= render_slot(@inner_block) %></.link>
    </li>
    """
  end
end
