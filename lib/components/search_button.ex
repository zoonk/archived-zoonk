defmodule ZoonkWeb.Components.SearchButton do
  @moduledoc """
  Renders a search button.

  This navigates to a search page/modal when clicked or using Cmd/Ctrl + K.
  """
  use ZoonkWeb, :live_component

  attr :class, :string, default: nil, doc: "the optional additional classes to add to the button element"
  attr :patch, :string, required: true, doc: "the path to patch to when the button is clicked"

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div id="search-button" phx-target={@myself} phx-window-keydown="open" class={@class}>
      <.link
        patch={@patch}
        class="ring-slate-900/10 flex h-10 sm:w-60 items-center space-x-3 rounded-lg bg-white px-2 sm:px-4 text-left text-slate-400 shadow-sm ring-1 hover:ring-slate-300 focus:outline-none focus:ring-2 focus:ring-sky-500"
      >
        <svg
          width="24"
          height="24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
          class="flex-none text-slate-300 dark:text-slate-400"
          aria-hidden="true"
        >
          <path d="m19 19-3.5-3.5"></path>
          <circle cx="11" cy="11" r="6"></circle>
        </svg>

        <span class="hidden sm:flex sm:w-full sm:justify-between">
          <span class="flex-auto"><%= gettext("Search...") %></span>
          <abbr title="Command" class="flex items-center text-sm font-semibold text-slate-300 no-underline">⌘ K</abbr>
        </span>
      </.link>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def handle_event("open", %{"ctrlKey" => true, "key" => "k"}, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.patch)}
  end

  def handle_event("open", %{"metaKey" => true, "key" => "k"}, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.patch)}
  end

  def handle_event("open", _params, socket) do
    {:noreply, socket}
  end
end
