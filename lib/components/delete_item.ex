defmodule UneebeeWeb.Components.DeleteItem do
  @moduledoc """
  Reusable component for deleting items.
  """
  use UneebeeWeb, :live_component

  import UneebeeWeb.Components.Input

  attr :id, :string, required: true
  attr :name, :string, required: true

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <form phx-submit="delete" phx-target={@myself} id="delete-form">
      <div class="flex flex-wrap items-center gap-2 bg-gray-50 p-4 sm:flex-nowrap sm:px-6 lg:px-8">
        <h1 class="text-base font-semibold leading-7 text-gray-900"><%= gettext("Delete") %></h1>

        <div class="ml-auto">
          <.button type="submit" icon="tabler-trash-x" color={:alert} phx-disable-with={gettext("Deleting...")}>
            <%= gettext("Delete") %>
          </.button>
        </div>
      </div>

      <div class="container">
        <p class="pb-4 text-sm text-gray-600">
          <%= dgettext("orgs", "Deleting this item will remove all of its content. This action cannot be undone.") %>
        </p>

        <.input type="text" label={dgettext("orgs", "Type CONFIRM to delete %{name}.", name: @name)} name="confirmation" id="confirmation" required value="" />

        <span :if={@error_msg} class="text-sm text-pink-500"><%= @error_msg %></span>
      </div>
    </form>
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, error_msg: nil)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("delete", %{"confirmation" => confirmation}, socket) do
    if confirmation == dgettext("orgs", "CONFIRM") do
      notify_parent()
      {:noreply, socket}
    else
      {:noreply, assign(socket, error_msg: error_message(confirmation))}
    end
  end

  defp notify_parent do
    send(self(), {__MODULE__})
    :ok
  end

  defp error_message(confirmation) do
    dgettext("orgs", "Confirmation message does not match. You typed: %{confirmation} but you need to type %{message}.",
      confirmation: confirmation,
      message: dgettext("orgs", "CONFIRM")
    )
  end
end
