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
    default: :primary,
    values: [:black, :alert, :success, :primary, :alert_light, :info_light, :success_light],
    doc: "the background color"

  attr :icon, :string, default: nil, doc: "name of the icon to add to the button"
  attr :class, :string, default: nil, doc: "the optional additional classes to add to the button element"
  attr :rest, :global, include: ~w(disabled form name type value)
  attr :size, :atom, default: :md, values: [:md, :lg], doc: "the button size"
  attr :shadow, :boolean, default: false, doc: "whether to add a shadow to the button"

  slot :inner_block, required: true, doc: "the inner block that renders the button content"

  def button(assigns) do
    ~H"""
    <button
      class={[
        "inline-flex items-center justify-center gap-2",
        "rounded-lg px-4 focus:outline-offset-2 phx-submit-loading:opacity-75",
        "text-sm font-semibold leading-6",
        "disabled:cursor-not-allowed disabled:bg-gray-200 disabled:text-gray-400",
        @color == :black && "bg-gray-700 text-white hover:bg-gray-900 focus:outline-gray-700",
        @color == :alert && "bg-pink-500 text-white hover:bg-pink-700 focus:outline-pink-500",
        @color == :success && "bg-teal-500 text-white hover:bg-teal-700 focus:outline-teal-500",
        @color == :primary && "bg-indigo-500 text-white hover:bg-indigo-700 focus:outline-indigo-500",
        @color == :alert_light && "bg-pink-50 text-pink-900 hover:bg-pink-200 focus:outline-pink-50",
        @color == :info_light && "bg-cyan-50 text-cyan-900 hover:bg-cyan-200 focus:outline-cyan-50",
        @color == :success_light && "bg-teal-50 text-teal-900 hover:bg-teal-200 focus:outline-teal-50",
        @size == :md && "py-2",
        @size == :lg && "py-3",
        @shadow && @color == :black && "shadow-b-gray active:shadow-b-gray-pressed",
        @shadow && @color == :alert && "shadow-b-pink active:shadow-b-pink-pressed",
        @shadow && @color == :success && "shadow-b-teal active:shadow-b-teal-pressed",
        @shadow && @color == :primary && "shadow-b-indigo active:shadow-b-indigo-pressed",
        @shadow && @color == :alert_light && "shadow-b-pink active:shadow-b-pink-pressed",
        @shadow && @color == :info_light && "shadow-b-cyan active:shadow-b-cyan-pressed",
        @shadow && @color == :success_light && "shadow-b-teal active:shadow-b-teal-pressed",
        @class
      ]}
      {@rest}
    >
      <.icon :if={@icon} name={@icon} class="h-5 w-5 -ml-0.5 mr-1" /> <%= render_slot(@inner_block) %>
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
        "disabled:cursor-not-allowed disabled:bg-gray-200 disabled:text-gray-400",
        "bg-pink-50 text-pink-900 hover:bg-pink-200 focus:outline-pink-50",
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
