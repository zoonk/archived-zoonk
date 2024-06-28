# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule ZoonkWeb.Components.Drawer do
  @moduledoc """
  Drawer components.
  """
  use Phoenix.Component

  import ZoonkWeb.Components.Icon
  import ZoonkWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders a drawer.

  ## Examples

      <.drawer id="mobile-nav">
        This is a drawer.
      </.drawer>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.drawer id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another drawer.
      </.drawer>

  """
  attr :id, :string, required: true, doc: "the id of the drawer container"
  attr :on_cancel, JS, default: %JS{}, doc: "the JS command to run when the drawer is canceled"

  slot :inner_block, required: true, doc: "the inner block that renders the drawer content"

  def drawer(assigns) do
    ~H"""
    <div id={@id} class="relative z-50 hidden" role="dialog" aria-modal="true" phx-remove={hide_drawer(@id)} data-cancel={JS.exec(@on_cancel, "phx-remove")}>
      <div class="bg-gray-900/80 fixed inset-0" id={"#{@id}-backdrop"} aria-hidden="true" />

      <div class="fixed inset-0 flex">
        <.focus_wrap
          id={"#{@id}-container"}
          phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
          phx-key="escape"
          phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
          class="relative mr-16 flex w-full max-w-xs flex-1"
        >
          <div class="absolute top-0 left-full flex w-16 justify-center pt-5" id={"#{@id}-close"}>
            <button type="button" class="-m-2.5 p-2.5 text-white" phx-click={JS.exec("data-cancel", to: "##{@id}")}>
              <.icon name="tabler-x" title={gettext("Close sidebar")} class="h-6 w-6" />
            </button>
          </div>

          <%= render_slot(@inner_block) %>
        </.focus_wrap>
      </div>
    </div>
    """
  end

  @doc """
  Shows the drawer.
  """
  def show_drawer(js \\ %JS{}, id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(to: "##{id}-backdrop", time: 300, transition: {"transition-opacity ease-linear duration-300", "opacity-0", "opacity-100"})
    |> JS.show(to: "##{id}-container", time: 300, transition: {"transition ease-in-out duration-300 transform", "-translate-x-full", "translate-x-0"}, display: "flex")
    |> JS.show(to: "##{id}-close", time: 300, transition: {"ease-in-out duration-300", "opacity-0", "opacity-100"}, display: "flex")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  @doc """
  Hides the drawer.
  """
  def hide_drawer(js \\ %JS{}, id) do
    js
    |> JS.hide(to: "##{id}-backdrop", time: 300, transition: {"transition-opacity ease-linear duration-300", "opacity-100", "opacity-0"})
    |> JS.hide(to: "##{id}-container", time: 300, transition: {"transition ease-in-out duration-300 transform", "translate-x-0", "-translate-x-full"})
    |> JS.hide(to: "##{id}-close", time: 300, transition: {"ease-in-out duration-300", "opacity-100", "opacity-0"})
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end
end
