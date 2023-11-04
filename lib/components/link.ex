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
    values: [:black, :alert, :black_light, :alert_light, :info_light]

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
        @color == :alert && "bg-pink-500 text-white shadow-b-pink-700 active:shadow-b-pink-700-pressed hover:bg-pink-700 focus:outline-pink-500",
        @color == :black_light && "bg-gray-light3x text-gray-dark2x shadow-b-gray-light active:shadow-b-gray-light-pressed hover:bg-gray-light2x focus:outline-gray-light3x",
        @color == :alert_light && "bg-pink-50 text-pink-900 shadow-b-pink-400 active:shadow-b-pink-400-pressed hover:bg-pink-200 focus:outline-pink-50",
        @color == :info_light && "bg-cyan-50 text-cyan-900 shadow-b-cyan-400 active:shadow-b-cyan-400-pressed hover:bg-cyan-200 focus:outline-cyan-50",
        @class
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %> <.icon :if={@icon} name={@icon} class="h-4 w-4" />
    </.link>
    """
  end
end
