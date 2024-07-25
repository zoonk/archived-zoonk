defmodule ZoonkWeb.Live.Flash do
  @moduledoc """
  Allow to display flash messages in LiveView components.

  This solution was shared by [Rebeca Le](https://sevenseacat.net/posts/2023/flash-messages-in-phoenix-liveview-components/).
  """
  import Phoenix.LiveView

  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

  @spec put_flash!(Socket.t(), atom(), String.t()) :: Socket.t()
  def put_flash!(socket, type, message) do
    send(self(), {:put_flash, type, message})
    socket
  end

  @spec on_mount(atom(), LiveView.unsigned_params(), map(), Socket.t()) :: {:cont, Socket.t()}
  def on_mount(_action, _params, _session, socket) do
    {:cont, attach_hook(socket, :flash, :handle_info, &maybe_receive_flash/2)}
  end

  defp maybe_receive_flash({:put_flash, type, message}, socket) do
    {:halt, put_flash(socket, type, message)}
  end

  defp maybe_receive_flash(_action, socket), do: {:cont, socket}
end
