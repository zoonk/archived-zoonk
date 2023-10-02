# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Link do
  @moduledoc """
  Link components.
  """
  use Phoenix.Component

  import UneebeeWeb.Components.Icon

  @doc """
  Renders a styled link using our default style guide.
  """
  attr :color, :atom, default: :primary, values: [:primary, :black, :alert], doc: "the color of the link"
  attr :class, :string, default: nil, doc: "the optional additional classes to add to the header element"
  attr :rest, :global, include: ~w(href method navigate)

  slot :inner_block, required: true

  def link_styled(assigns) do
    ~H"""
    <.link
      class={[
        "font-semibold hover:underline",
        @color == :primary && "text-primary",
        @color == :black && "text-gray-dark",
        @color == :alert && "text-alert",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  @doc """
  Renders a link but styled like a button.
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
    ]

  attr :class, :string, default: nil
  attr :icon, :string, default: nil
  attr :rest, :global, include: ~w(href method navigate)

  slot :inner_block

  def link_button(assigns) do
    ~H"""
    <.link
      class={[
        "flex justify-center items-center gap-2",
        "rounded-lg py-2 px-3 focus:outline-offset-2",
        "text-sm font-semibold leading-6",
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
    </.link>
    """
  end
end
