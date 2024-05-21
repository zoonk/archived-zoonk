# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule ZoonkWeb.Components.Badge do
  @moduledoc """
  Badge components.
  """
  use Phoenix.Component

  import ZoonkWeb.Components.Icon

  @doc """
  Renders a badge.

  ## Examples

      <.badge>1</.badge>
      <.badge color={:alert}>2</.badge>
      <.badge color={:success}>3</.badge>
      <.badge color={:info}>4</.badge>
      <.badge color={:warning}>5</.badge>
  """
  attr :color, :atom,
    default: :info,
    values: [:black, :alert, :info, :primary, :success, :warning, :bronze],
    doc: "the background color"

  attr :icon, :string, default: nil, doc: "name of the icon to add to the badge"
  attr :class, :string, default: nil, doc: "the optional additional classes to add to the badge element"
  attr :title, :string, default: nil, doc: "the optional title to add to the badge element"
  attr :rest, :global, doc: "the optional additional attributes to add to the badge element"

  slot :inner_block, required: true, doc: "the inner block that renders the badge content"

  def badge(assigns) do
    ~H"""
    <span
      class={[
        "inline-flex h-fit flex-shrink-0 items-center gap-x-2 rounded-md px-2 py-1 text-xs font-medium ring-1 ring-inset",
        @color == :black && "ring-gray-600/20 bg-gray-50 text-gray-700",
        @color == :alert && "ring-pink-600/20 bg-pink-50 text-pink-700",
        @color == :primary && "ring-blue-600/20 bg-blue-50 text-blue-700",
        @color == :info && "ring-cyan-600/20 bg-cyan-50 text-cyan-700",
        @color == :success && "ring-teal-600/20 bg-teal-50 text-teal-700",
        @color == :warning && "ring-amber-600/20 bg-amber-50 text-amber-700",
        @color == :bronze && "ring-orange-600/20 bg-orange-50 text-orange-700",
        @class
      ]}
      title={@title}
      {@rest}
    >
      <.icon :if={@icon} name={@icon} title={@title} class="h-3 w-3" /> <%= render_slot(@inner_block) %>
    </span>
    """
  end
end
