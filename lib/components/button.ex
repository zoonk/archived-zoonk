# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Button do
  @moduledoc """
  Button components.
  """
  use Phoenix.Component

  import UneebeeWeb.Components.Icon

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :color, :atom,
    default: :black,
    values: [:black, :alert, :info, :success, :warning, :black_light, :alert_light, :info_light, :success_light, :warning_light],
    doc: "the background color"

  attr :icon, :string, default: nil, doc: "name of the icon to add to the button"
  attr :class, :string, default: nil, doc: "the optional additional classes to add to the button element"
  attr :rest, :global, include: ~w(disabled form name type value)

  slot :inner_block, required: true, doc: "the inner block that renders the button content"

  def button(assigns) do
    ~H"""
    <button
      class={[
        "flex items-center justify-center gap-2",
        "rounded-lg px-3 py-2 focus:outline-offset-2 phx-submit-loading:opacity-75",
        "text-sm font-semibold leading-6",
        "disabled:bg-gray-light2x disabled:text-gray-light disabled:cursor-not-allowed",
        @color == :black && "bg-gray-dark shadow-b-gray text-white hover:bg-gray-dark2x focus:outline-gray-dark active:shadow-b-gray-pressed",
        @color == :alert && "shadow-b-pink-700 bg-pink-500 text-white hover:bg-pink-700 focus:outline-pink-500 active:shadow-b-pink-700-pressed",
        @color == :success && "bg-success shadow-b-success-dark text-white hover:bg-success-dark focus:outline-success active:shadow-b-success-dark-pressed",
        @color == :info && "shadow-b-cyan-700 bg-cyan-500 text-white hover:bg-cyan-700 focus:outline-cyan-500 active:shadow-b-cyan-700-pressed",
        @color == :warning && "bg-warning shadow-b-warning-dark text-white hover:bg-warning-dark focus:outline-warning active:shadow-b-warning-dark-pressed",
        @color == :black_light && "bg-gray-light3x text-gray-dark2x shadow-b-gray-light hover:bg-gray-light2x focus:outline-gray-light3x active:shadow-b-gray-light-pressed",
        @color == :alert_light && "text-pink-7002x shadow-b-pink-400 bg-pink-50 hover:bg-pink-200 focus:outline-pink-50 active:shadow-b-pink-400-pressed",
        @color == :info_light && "shadow-b-cyan-400 bg-cyan-50 text-cyan-900 hover:bg-cyan-200 focus:outline-cyan-50 active:shadow-b-cyan-400-pressed",
        @color == :success_light &&
          "bg-success-light3x text-success-dark2x shadow-b-success-light hover:bg-success-light2x focus:outline-success-light3x active:shadow-b-success-light-pressed",
        @color == :warning_light &&
          "bg-warning-light3x text-warning-dark2x shadow-b-warning-light hover:bg-warning-light2x focus:outline-warning-light3x active:shadow-b-warning-light-pressed",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %> <.icon :if={@icon} name={@icon} class="h-4 w-4" />
    </button>
    """
  end

  @doc """
  Renders a button with an icon only.

  ## Examples

      <.icon_button icon="tabler-x" label="Remove" color={:alert} />
      <.icon_button icon="tabler-add" label="Add" phx-click="add" />
  """
  attr :icon, :string, required: true, doc: "name of the icon to add to the button"
  attr :label, :string, required: true, doc: "the button's label for screen readers"
  attr :rest, :global, include: ~w(disabled form name type value)

  attr :size, :atom, default: :lg, values: [:sm, :md, :lg], doc: "the button size"

  def icon_button(assigns) do
    ~H"""
    <button
      class={[
        "flex items-center justify-center",
        "rounded-lg px-3 py-2 focus:outline-offset-2 phx-submit-loading:opacity-75",
        "text-sm font-semibold leading-6",
        "disabled:bg-gray-light2x disabled:text-gray-light disabled:cursor-not-allowed",
        "shadow-b-pink-400 bg-pink-50 text-pink-900 hover:bg-pink-200 focus:outline-pink-50 active:shadow-b-pink-400-pressed",
        @size == :sm && "h-6 w-6",
        @size == :md && "h-8 w-8",
        @size == :lg && "h-10 w-10"
      ]}
      title={@label}
      {@rest}
    >
      <span class="sr-only"><%= @label %></span> <.icon name={@icon} />
    </button>
    """
  end
end
