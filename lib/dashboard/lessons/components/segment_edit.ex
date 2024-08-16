defmodule ZoonkWeb.Components.Dashboard.SegmentEdit do
  @moduledoc false
  use Phoenix.Component

  import ZoonkWeb.Components.Button
  import ZoonkWeb.Components.Input
  import ZoonkWeb.Gettext

  def segment_edit(assigns) do
    ~H"""
    <form id="segment-edit-form" class="space-y-4" phx-submit="update-segment">
      <.input type="text" name="segment" value={@segment} />

      <.button type="submit" icon="tabler-pencil" phx-disable-with={gettext("Updating...")}>
        <%= gettext("Update") %>
      </.button>
    </form>
    """
  end
end
