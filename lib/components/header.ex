# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Header do
  @moduledoc """
  Header components.
  """
  use Phoenix.Component

  import UneebeeWeb.Components.Icon

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil, doc: "the optional additional classes to add to the header element"
  attr :icon, :string, default: nil, doc: "the optional icon name to add to the header element"

  slot :inner_block, required: true, doc: "the inner block that renders the header content"
  slot :subtitle, doc: "renders a subtitle under the header content"
  slot :actions, doc: "renders a slot for actions, such as a button, at the bottom of the header"

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-6", @class]}>
      <div>
        <h1 class="text-lg font-semibold text-indigo-500">
          <.icon :if={@icon} name={@icon} class="mr-1 h-4 w-4" />
          <span><%= render_slot(@inner_block) %></span>
        </h1>

        <p :if={@subtitle != []} class="mt-2 text-sm leading-6 text-gray-500"><%= render_slot(@subtitle) %></p>
      </div>

      <div :if={@actions != []} class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end
end
