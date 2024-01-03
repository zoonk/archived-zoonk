# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.SearchBox do
  @moduledoc """
  Search box components.
  """
  use Phoenix.Component

  import UneebeeWeb.Components.Utils
  import UneebeeWeb.Gettext

  alias Phoenix.LiveView.JS

  attr :id, :string, required: true, doc: "the id of the search box container"
  attr :show, :boolean, default: false, doc: "whether to show the search box on mount"
  attr :on_cancel, JS, default: %JS{}, doc: "the JS command to run when the search box is canceled"
  attr :empty, :boolean, default: true, doc: "whether the search results are empty"
  attr :rest, :global, doc: "the rest of the attributes"

  slot :inner_block, required: true, doc: "the inner block that renders the search box content"

  def search_box(assigns) do
    ~H"""
    <form id={@id} phx-mounted={@show && show_modal(@id)} phx-remove={hide_modal(@id)} data-cancel={JS.exec(@on_cancel, "phx-remove")} class="relative z-50 hidden" {@rest}>
      <div id={"#{@id}-bg"} class="bg-gray-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />

      <div class="fixed inset-0 overflow-y-auto" aria-labelledby={"#{@id}-title"} aria-describedby={"#{@id}-description"} role="dialog" aria-modal="true" tabindex="0">
        <div class="min-h-dvh flex items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="mx-auto max-w-xl transform divide-y divide-gray-100 overflow-hidden rounded-xl bg-white shadow-2xl ring-1 ring-black ring-opacity-5 transition-all"
            >
              <div class="relative" id={"#{@id}-content"}>
                <svg class="pointer-events-none absolute top-3.5 left-4 h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path
                    fill-rule="evenodd"
                    d="M9 3.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM2 9a7 7 0 1112.452 4.391l3.328 3.329a.75.75 0 11-1.06 1.06l-3.329-3.328A7 7 0 012 9z"
                    clip-rule="evenodd"
                  />
                </svg>

                <input
                  type="text"
                  name="term"
                  class="h-12 w-full border-0 bg-transparent pr-4 pl-11 text-gray-900 placeholder:text-gray-400 focus:ring-0 sm:text-sm"
                  placeholder={gettext("Search...")}
                  role="combobox"
                  aria-expanded="false"
                  aria-controls="options"
                  phx-debounce
                />
              </div>

              <ul :if={!@empty} class="max-h-72 scroll-py-2 overflow-y-auto py-2 text-sm text-gray-800" id="options" role="listbox">
                <%= render_slot(@inner_block) %>
              </ul>

              <p :if={@empty} class="p-4 text-sm text-gray-500"><%= gettext("No results found.") %></p>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </form>
    """
  end

  attr :id, :string, required: true, doc: "the id of the search item"
  attr :name, :string, required: true, doc: "the label of the search item"
  attr :rest, :global, include: ~w(href method navigate patch)

  def search_item(assigns) do
    ~H"""
    <li class="select-none px-4 py-2" id={@id} role="option" tabindex="-1">
      <.link {@rest}><%= @name %></.link>
    </li>
    """
  end
end
