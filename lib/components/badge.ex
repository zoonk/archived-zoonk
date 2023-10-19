# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Badge do
  @moduledoc """
  Badge components.
  """
  use Phoenix.Component

  import UneebeeWeb.Components.Icon

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
    default: :info_light,
    values: [:black, :alert, :info, :success, :warning, :black_light, :alert_light, :info_light, :success_light, :warning_light],
    doc: "the background color"

  attr :icon, :string, required: true, doc: "name of the icon to add to the badge"
  attr :class, :string, default: nil, doc: "the optional additional classes to add to the badge element"
  attr :rest, :global, doc: "the optional additional attributes to add to the badge element"

  slot :inner_block, required: true, doc: "the inner block that renders the badge content"

  def badge(assigns) do
    ~H"""
    <span
      class={[
        "inline-flex items-center px-2.5 py-0.5 w-max max-w-full gap-1 rounded-full text-xs font-medium leading-4",
        @color == :black && "bg-gray-dark text-white",
        @color == :alert && "bg-alert text-white",
        @color == :success && "bg-success text-white",
        @color == :info && "bg-info text-white",
        @color == :warning && "bg-warning text-white",
        @color == :black_light && "bg-gray-light3x text-gray-dark2x",
        @color == :alert_light && "bg-alert-light3x text-alert-dark2x",
        @color == :info_light && "bg-info-light3x text-info-dark2x",
        @color == :success_light && "bg-success-light3x text-success-dark2x",
        @color == :warning_light && "bg-warning-light3x text-warning-dark2x",
        @class
      ]}
      {@rest}
    >
      <.icon name={@icon} class="h-3 w-3" /> <%= render_slot(@inner_block) %>
    </span>
    """
  end
end
