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
        @color == :primary && "text-indigo-500",
        @color == :black && "text-gray-dark",
        @color == :alert && "text-pink-500",
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
  attr :id, :string, default: nil

  attr :color, :atom,
    default: :black,
    values: [:black, :alert, :info, :success, :warning, :black_light, :alert_light, :info_light, :success_light, :warning_light]

  attr :class, :string, default: nil
  attr :icon, :string, default: nil
  attr :rest, :global, include: ~w(href method navigate patch)

  slot :inner_block

  def link_button(assigns) do
    ~H"""
    <.link
      id={@id}
      class={[
        "flex justify-center items-center gap-2",
        "rounded-lg py-2 px-3 focus:outline-offset-2",
        "text-sm font-semibold leading-6",
        @color == :black && "bg-gray-dark shadow-b-gray active:shadow-b-gray-pressed text-white hover:bg-gray-dark2x focus:outline-gray-dark",
        @color == :alert &&
          "bg-pink-500 text-white shadow-b-pink-700 active:shadow-b-pink-700-pressed hover:bg-pink-700 focus:outline-pink-500",
        @color == :success && "bg-success text-white shadow-b-success-dark active:shadow-b-success-dark-pressed hover:bg-success-dark focus:outline-success",
        @color == :info && "bg-info text-white shadow-b-info-dark active:shadow-b-info-dark-pressed hover:bg-info-dark focus:outline-info",
        @color == :warning && "bg-warning text-white shadow-b-warning-dark active:shadow-b-warning-dark-pressed hover:bg-warning-dark focus:outline-warning",
        @color == :black_light && "bg-gray-light3x text-gray-dark2x shadow-b-gray-light active:shadow-b-gray-light-pressed hover:bg-gray-light2x focus:outline-gray-light3x",
        @color == :alert_light && "bg-pink-50 text-pink-7002x shadow-b-pink-400 active:shadow-b-pink-400-pressed hover:bg-pink-200 focus:outline-pink-50",
        @color == :info_light && "bg-info-light3x text-info-dark2x shadow-b-info-light active:shadow-b-info-light-pressed hover:bg-info-light2x focus:outline-info-light3x",
        @color == :success_light &&
          "bg-success-light3x text-success-dark2x shadow-b-success-light active:shadow-b-success-light-pressed hover:bg-success-light2x focus:outline-success-light3x",
        @color == :warning_light &&
          "bg-warning-light3x text-warning-dark2x shadow-b-warning-light active:shadow-b-warning-light-pressed hover:bg-warning-light2x focus:outline-warning-light3x",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %> <.icon :if={@icon} name={@icon} class="h-4 w-4" />
    </.link>
    """
  end
end
