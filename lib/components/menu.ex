# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule ZoonkWeb.Components.Menu do
  @moduledoc """
  Menu components.
  """
  use Phoenix.Component

  import ZoonkWeb.Components.Icon

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
  attr :icon, :string, default: nil, doc: "Icon displayed above the title."
  attr :title, :string, required: true, doc: "Menu title."
  attr :rest, :global, include: ~w(href method navigate)
  attr :class, :string, default: nil

  def menu_item(assigns) do
    ~H"""
    <li aria-current={@active and "page"} class={@class}>
      <.link
        class={[
          "group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-gray-700 hover:bg-gray-50 hover:text-indigo-600",
          @active && "bg-gray-50 text-indigo-600",
          not @active && "text-gray-700 hover:text-indigo-600 hover:bg-gray-50"
        ]}
        {@rest}
      >
        <div :if={@icon} class={[@active && "text-indigo-600", not @active && "text-gray-400 group-hover:text-indigo-600"]}>
          <.icon name={@icon} class="h-6 w-6" aria-hidden="true" />
        </div>

        <span
          :if={is_nil(@icon)}
          class="text-[0.625rem] flex h-6 w-6 shrink-0 items-center justify-center rounded-lg border border-gray-200 bg-white font-medium text-gray-400 group-hover:border-indigo-600 group-hover:text-indigo-600"
        >
          <%= String.first(@title) %>
        </span>

        <%= @title %>
      </.link>
    </li>
    """
  end
end
