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
    values: [
      :black,
      :alert,
      :info,
      :success,
      :warning,
      :black_light,
      :alert_light,
      :info_light,
      :success_light,
      :warning_light
    ],
    doc: "the background color"

  attr :icon, :string, default: nil, doc: "name of the icon to add to the button"
  attr :class, :string, default: nil, doc: "the optional additional classes to add to the button element"
  attr :rest, :global, include: ~w(disabled form name type value)

  slot :inner_block, required: true, doc: "the inner block that renders the button content"

  def button(assigns) do
    ~H"""
    <button
      class={[
        "flex justify-center items-center gap-2",
        "phx-submit-loading:opacity-75 rounded-lg py-2 px-3 focus:outline-offset-2",
        "text-sm font-semibold leading-6",
        "disabled:bg-gray-light2x disabled:cursor-not-allowed disabled:text-gray-light",
        @color == :black && "bg-gray-dark text-white active:text-white/80 hover:bg-gray-dark2x focus:outline-gray-dark",
        @color == :alert && "bg-alert text-white active:text-white/80 hover:bg-alert-dark focus:outline-alert",
        @color == :success && "bg-success text-white active:text-white/80 hover:bg-success-dark focus:outline-success",
        @color == :info && "bg-info text-white active:text-white/80 hover:bg-info-dark focus:outline-info",
        @color == :warning && "bg-warning text-white active:text-white/80 hover:bg-warning-dark focus:outline-warning",
        @color == :black_light && "bg-gray-light3x text-gray-dark2x hover:bg-gray-light2x focus:outline-gray-light3x",
        @color == :alert_light && "bg-alert-light3x text-alert-dark2x hover:bg-alert-light2x focus:outline-alert-light3x",
        @color == :info_light && "bg-info-light3x text-info-dark2x hover:bg-info-light2x focus:outline-info-light3x",
        @color == :success_light &&
          "bg-success-light3x text-success-dark2x hover:bg-success-light2x focus:outline-success-light3x",
        @color == :warning_light &&
          "bg-warning-light3x text-warning-dark2x hover:bg-warning-light2x focus:outline-warning-light3x",
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

  attr :color, :atom,
    default: :black,
    values: [
      :black,
      :alert,
      :info,
      :success,
      :warning,
      :black_light,
      :alert_light,
      :info_light,
      :success_light,
      :warning_light
    ],
    doc: "the background color"

  attr :size, :atom, default: :lg, values: [:sm, :md, :lg], doc: "the button size"

  def icon_button(assigns) do
    ~H"""
    <button
      class={[
        "flex items-center justify-center",
        "phx-submit-loading:opacity-75 rounded-lg py-2 px-3 focus:outline-offset-2",
        "text-sm font-semibold leading-6",
        "disabled:bg-gray-light2x disabled:cursor-not-allowed disabled:text-gray-light",
        @color == :black && "bg-gray-dark text-white active:text-white/80 hover:bg-gray-dark2x focus:outline-gray-dark",
        @color == :alert && "bg-alert text-white active:text-white/80 hover:bg-alert-dark focus:outline-alert",
        @color == :success && "bg-success text-white active:text-white/80 hover:bg-success-dark focus:outline-success",
        @color == :info && "bg-info text-white active:text-white/80 hover:bg-info-dark focus:outline-info",
        @color == :warning && "bg-warning text-white active:text-white/80 hover:bg-warning-dark focus:outline-warning",
        @color == :black_light && "bg-gray-light3x text-gray-dark2x hover:bg-gray-light3x focus:outline-gray-light3x",
        @color == :alert_light && "bg-alert-light3x text-alert-dark2x hover:bg-alert-light2x focus:outline-alert-light3x",
        @color == :info_light && "bg-info-light3x text-info-dark2x hover:bg-info-light2x focus:outline-info-light3x",
        @color == :success_light &&
          "bg-success-light3x text-success-dark2x hover:bg-success-light2x focus:outline-success-light3x",
        @color == :warning_light &&
          "bg-warning-light3x text-warning-dark2x hover:bg-warning-light2x focus:outline-warning-light3x",
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

  @doc """
  Renders a button with a transparent background.

  ## Examples

      <.transparent_button icon="tabler-x" color={:alert} phx-click="remove">Remove</.transparent_button>
  """
  attr :icon, :string, required: true, doc: "name of the icon to add to the button"
  attr :color, :atom, default: :info, values: [:info, :alert, :success, :warning], doc: "the background color"
  attr :rest, :global, include: ~w(disabled form name type value)

  slot :inner_block, required: true, doc: "the inner block that renders the button content"

  def transparent_button(assigns) do
    ~H"""
    <button
      class={[
        "flex items-center gap-1 bg-transparent focus:outline-offset-2 text-sm disabled:cursor-not-allowed disabled:text-gray-light",
        @color == :info && "text-info hover:text-info-dark focus:outline-info",
        @color == :alert && "text-alert hover:text-alert-dark focus:outline-alert",
        @color == :success && "text-success hover:text-success-dark focus:outline-success",
        @color == :warning && "text-warning hover:text-warning-dark focus:outline-warning"
      ]}
      {@rest}
    >
      <.icon name={@icon} class="h-4 w-4" /> <%= render_slot(@inner_block) %>
    </button>
    """
  end
end
