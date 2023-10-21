# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Details do
  @moduledoc """
  Details component.
  """
  use Phoenix.Component

  import UneebeeWeb.Components.Icon

  @doc """
  Renders a details component.

  ## Examples

      <.details title="Title">
        <p>Content</p>
      </.details>
  """
  attr :title, :string, required: true, doc: "Title to be displayed even when the component is collapsed."
  attr :class, :string, default: nil, doc: "Optional additional classes to add to the details element."
  attr :rounded, :boolean, default: true, doc: "Whether the details element should be rounded or not."

  slot :inner_block, required: true, doc: "Content to be displayed when the component is expanded."

  def details(assigns) do
    ~H"""
    <details class={[
      "group w-full shadow p-4 text-sm min-w-0",
      @rounded && "rounded-lg",
      @class
    ]}>
      <summary class="flex cursor-pointer items-center gap-1 font-bold">
        <.icon name="tabler-chevrons-down" class="group-open:hidden" gradient />
        <.icon name="tabler-chevrons-up" class="hidden group-open:inline" gradient />
        <span class="text-gradient truncate"><%= @title %></span>
      </summary>

      <%= render_slot(@inner_block) %>
    </details>
    """
  end
end
