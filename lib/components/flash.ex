# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule ZoonkWeb.Components.Flash do
  @moduledoc """
  Flash components.
  """
  use Phoenix.Component

  import ZoonkWeb.Components.Icon
  import ZoonkWeb.Components.Utils
  import ZoonkWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, default: "flash", doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      phx-hook={if @kind == :info, do: "ClearFlash", else: nil}
      data-kind={@kind}
      role="alert"
      class={[
        "fixed top-2 right-2 z-50 mr-2 w-80 rounded-lg p-3 ring-1 transition-opacity duration-500 ease-in-out sm:w-96",
        @kind == :info && "bg-teal-50 fill-cyan-700 text-teal-700 ring-teal-500",
        @kind == :error && "bg-pink-50 fill-pink-700 text-pink-700 shadow-md ring-pink-500"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="tabler-info-square-rounded" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="tabler-alert-square-rounded" class="h-4 w-4" />
        <%= @title %>
      </p>
      <p class="mt-2 text-sm leading-5"><%= msg %></p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="tabler-x" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  def flash_group(assigns) do
    ~H"""
    <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
    <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
    <.flash id="disconnected" kind={:error} title={gettext("We can't find the internet")} phx-disconnected={show("#disconnected")} phx-connected={hide("#disconnected")} hidden>
      <%= gettext("Attempting to reconnect") %> <.icon name="tabler-refresh" class="ml-1 h-3 w-3 animate-spin" />
    </.flash>
    """
  end
end
