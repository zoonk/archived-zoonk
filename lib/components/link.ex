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
  attr :class, :string, default: nil, doc: "the optional additional classes to add to the header element"
  attr :rest, :global, include: ~w(href method navigate)

  slot :inner_block, required: true

  def link_styled(assigns) do
    ~H"""
    <.link class={["font-semibold text-indigo-500 hover:underline", @class]} {@rest}>
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
    values: [:black, :alert, :primary, :white, :black_light, :alert_light, :info_light]

  attr :class, :string, default: nil
  attr :icon, :string, default: nil
  attr :rest, :global, include: ~w(href method navigate patch)
  attr :kind, :atom, values: [:text, :icon], default: :text

  slot :inner_block

  def link_button(assigns) do
    ~H"""
    <.link
      id={@id}
      class={[
        "inline-flex justify-center items-center gap-2",
        "rounded-lg py-2 px-3 focus:outline-offset-2",
        "text-sm font-semibold leading-6",
        @color == :black && "bg-gray-700 text-white hover:bg-gray-900 focus:outline-gray-700",
        @color == :alert && "bg-pink-500 text-white hover:bg-pink-700 focus:outline-pink-500",
        @color == :primary && "bg-indigo-500 text-white hover:bg-indigo-700 focus:outline-indigo-500",
        @color == :white && "bg-white text-gray-900 hover:bg-gray-50 ring-1 ring-inset ring-gray-300 focus:outline-gray-300",
        @color == :black_light && "bg-gray-50 text-gray-900 hover:bg-gray-200 focus:outline-gray-50",
        @color == :alert_light && "bg-pink-50 text-pink-900 hover:bg-pink-200 focus:outline-pink-50",
        @color == :info_light && "bg-cyan-50 text-cyan-900 hover:bg-cyan-200 focus:outline-cyan-50",
        @class
      ]}
      {@rest}
    >
      <.icon :if={@icon} name={@icon} class={["h-5 w-5", @kind == :text && "-ml-0.5 mr-1"]} />
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end
end
