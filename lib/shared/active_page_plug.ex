defmodule ZoonkWeb.Plugs.ActivePage do
  @moduledoc """
  This module is used to set the active page to the socket.
  """
  import Phoenix.Component
  import Phoenix.LiveView

  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

  @spec on_mount(atom(), LiveView.unsigned_params(), map(), Socket.t()) :: {:cont, Socket.t()}
  def on_mount(:default, _params, _session, socket) do
    {:cont, attach_hook(socket, :active_page, :handle_params, &set_active_page/3)}
  end

  # Get the view's name and convert it to an atom that can be used on the menu to check if the current view is active.
  defp set_active_page(_params, _url, socket) do
    active_page =
      case socket.view do
        view when is_atom(view) ->
          view
          |> Module.split()
          |> Enum.slice(-2..-1)
          |> maybe_remove_live()
          |> Enum.join("_")
          |> String.downcase()

        _invalid ->
          nil
      end

    {:cont, assign(socket, active_page: maybe_add_live_action(socket, active_page))}
  end

  # Add the live_action as the suffix to the active_page when it exists.
  defp maybe_add_live_action(%{assigns: %{live_action: live_action}}, active_page) do
    if live_action, do: convert_to_atom("#{active_page}_#{live_action}"), else: convert_to_atom(active_page)
  end

  ## When "Live" is the first item on the list, remove it.
  defp maybe_remove_live(["Live" | rest]), do: rest
  defp maybe_remove_live(list), do: list

  # We don't need the active_page for some views.
  # This means there won't be an existing atom.
  # This function just ignores errors from the atom conversion.
  defp convert_to_atom(view) do
    String.to_existing_atom(view)
  rescue
    ArgumentError -> nil
  end
end
