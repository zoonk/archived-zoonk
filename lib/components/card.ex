# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Card do
  @moduledoc """
  Form components.
  """
  use Phoenix.Component

  @doc """
  Renders a simple card.

  ## Examples

      <.card>
        card content
      </.card>
  """
  attr :class, :string, default: nil, doc: "the form class"

  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={["bg-white rounded-xl shadow p-4", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
