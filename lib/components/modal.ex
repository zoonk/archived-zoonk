# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Modal do
  @moduledoc """
  Modal components.
  """
  use Phoenix.Component

  import UneebeeWeb.Components.Icon
  import UneebeeWeb.Components.Utils
  import UneebeeWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true, doc: "the id of the modal container"
  attr :show, :boolean, default: false, doc: "whether to show the modal on mount"
  attr :on_cancel, JS, default: %JS{}, doc: "the JS command to run when the modal is canceled"
  slot :inner_block, required: true, doc: "the inner block that renders the modal content"
  slot :actions, doc: "the slot for modal actions, such as a confirm and cancel"

  def modal(assigns) do
    ~H"""
    <div id={@id} phx-mounted={@show && show_modal(@id)} phx-remove={hide_modal(@id)} data-cancel={JS.exec(@on_cancel, "phx-remove")} class="relative z-50 hidden">
      <div id={"#{@id}-bg"} class="bg-gray-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div class="fixed inset-0 overflow-y-auto" aria-labelledby={"#{@id}-title"} aria-describedby={"#{@id}-description"} role="dialog" aria-modal="true" tabindex="0">
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-gray-700/10 ring-gray-700/10 relative hidden h-screen bg-white p-8 shadow-lg ring-1 transition lg:h-auto lg:rounded-2xl"
            >
              <div class="absolute top-6 right-5">
                <button phx-click={JS.exec("data-cancel", to: "##{@id}")} type="button" class="-m-3 flex-none p-3 opacity-20 hover:opacity-40" aria-label={gettext("close")}>
                  <.icon name="tabler-x" class="h-5 w-5" />
                </button>
              </div>

              <div id={"#{@id}-content"} class="space-y-4">
                <%= render_slot(@inner_block) %>

                <div :for={action <- @actions} class="mt-2 flex flex-col items-center justify-between gap-4 md:flex-row">
                  <%= render_slot(action) %>
                </div>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Shows a modal.
  """
  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  @doc """
  Hides a modal.
  """
  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end
end
