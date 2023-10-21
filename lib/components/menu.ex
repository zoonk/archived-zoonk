# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Menu do
  @moduledoc """
  Menu components.
  """
  use Phoenix.Component

  import UneebeeWeb.Components.Details
  import UneebeeWeb.Components.Icon

  attr :title, :string, required: true, doc: "Menu title."
  slot :inner_block, required: true, doc: "Inner block of the menu."

  def menu(assigns) do
    ~H"""
    <!-- Mobile menu -->
    <.details title={@title} rounded={false} class="bg-white/90 sticky top-0 z-50 backdrop-blur-sm lg:hidden">
      <nav class="mt-4">
        <ul class="divide-gray-light2x flex w-full flex-col divide-y"><%= render_slot(@inner_block) %></ul>
      </nav>
    </.details>
    <!-- Desktop menu menu -->
    <nav class="min-w-[200px] border-gray-light2x shadow-b-gray sticky top-4 hidden rounded-2xl border bg-white lg:flex">
      <ul class="divide-gray-light2x flex w-full flex-col divide-y"><%= render_slot(@inner_block) %></ul>
    </nav>
    """
  end

  @doc """
  Renders a menu item.

  ## Examples

      <.menu_item
        active={@live_action == :school_list}
        navigate={~p"/schools"}
        icon="tabler-school"
        title="Schools"
      />
  """
  attr :active, :boolean, default: false, doc: "Whether the menu is active or not."
  attr :icon, :string, required: true, doc: "Icon displayed above the title."
  attr :title, :string, required: true, doc: "Menu title."
  attr :rest, :global, include: ~w(href method navigate)

  slot :sub_menus, doc: "Sub menu items."

  def menu_item(assigns) do
    ~H"""
    <li
      class={[
        "text-gray-dark py-2 last:max-lg:pb-0 lg:first:rounded-t-2xl lg:last:rounded-b-2xl",
        not @active and "hover:bg-gray-light3x"
      ]}
      aria-current={@active and "page"}
    >
      <.link class="flex items-center gap-2 focus:outline-primary lg:items-center lg:p-2" title={@title} {@rest}>
        <.icon name={@icon} gradient={@active} class="h-3 w-3 lg:h-5 lg:w-5" />
        <span class={[@active and "text-gradient"]}><%= @title %></span>
      </.link>

      <ul :if={@sub_menus != [] && @active} class="px-5 lg:px-9"><%= render_slot(@sub_menus) %></ul>
    </li>
    """
  end

  @doc """
  Renders a sub menu item.

  ## Examples

      <.sub_menu
        active={@live_action == :school_list}
        navigate={~p"/schools"}
        title="Schools"
      />
  """
  attr :active, :boolean, default: false, doc: "Whether the menu is active or not."
  attr :title, :string, required: true, doc: "Menu title."
  attr :rest, :global, include: ~w(href method navigate)

  def sub_menu(assigns) do
    ~H"""
    <li class="text-gray-dark py-1 text-sm hover:bg-gray-light3x" aria-current={@active and "page"}>
      <.link class="focus:outline-primary" title={@title} {@rest}>
        <span class={[@active and "text-gradient"]}><%= @title %></span>
      </.link>
    </li>
    """
  end
end
