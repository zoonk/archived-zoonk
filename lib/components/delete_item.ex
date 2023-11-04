defmodule UneebeeWeb.Components.DeleteItem do
  @moduledoc """
  Reusable component for deleting items.
  """
  use UneebeeWeb, :live_component

  import UneebeeWeb.Components.Header
  import UneebeeWeb.Components.Input

  attr :id, :string, required: true
  attr :name, :string, required: true

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="card p-4">
      <.header>
        <%= dgettext("orgs", "Delete item") %>
        <:subtitle>
          <%= dgettext("orgs", "Deleting this item will remove all of its content. This action cannot be undone.") %>
        </:subtitle>
      </.header>

      <form phx-submit="delete" phx-target={@myself} id="delete-form" class="mt-4">
        <.input type="text" label={dgettext("orgs", "Type CONFIRM to delete %{name}.", name: @name)} name="confirmation" id="confirmation" required value="" />

        <span :if={@error_msg} class="text-sm text-pink-500"><%= @error_msg %></span>

        <div class="mt-4 flex items-center gap-2">
          <.button type="submit" icon="tabler-trash-x" color={:alert} phx-disable-with={gettext("Deleting...")}>
            <%= dgettext("orgs", "Delete item") %>
          </.button>
        </div>
      </form>
    </div>
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
