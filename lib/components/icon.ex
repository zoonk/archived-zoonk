# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Icon do
  @moduledoc """
  Icon components.
  """
  use Phoenix.Component

  @doc """
  Renders a [Tabler Icon](https://tabler-icons.io/).

  Icons are extracted from our `assets/vendor/tabler` directory and bundled
  within our compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="tabler-x" />
      <.icon name="tabler-refresh" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true, doc: "the name of the icon from the tabler library"
  attr :class, :any, default: nil, doc: "the optional additional classes to add to the icon element"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the icon element"
  attr :title, :string, default: nil, doc: "the optional title to add to the icon element"

  def icon(%{name: "tabler-" <> _} = assigns) do
    ~H"""
    <span {@rest} title={@title} class={["shrink-0", @name, @class]} aria-hidden={is_nil(@title)}>
      <span :if={@title} class="sr-only"><%= @title %></span>
    </span>
    """
  end
end
