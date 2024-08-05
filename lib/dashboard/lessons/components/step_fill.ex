defmodule ZoonkWeb.Components.Dashboard.StepFill do
  @moduledoc false
  use ZoonkWeb, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div id="segments" class="flex gap-2">
      <.link :for={{segment, index} <- Enum.with_index(@segments)} class={["bg-white p-2 rounded-md shadow-sm", is_nil(segment) && "semibold text-teal-500"]}>
        <%= get_segment(segment, index, @options) %>
      </.link>
    </div>
    """
  end

  defp get_segment(nil, index, options), do: get_segment_option(options, index).title
  defp get_segment(segment, _idx, _options), do: segment

  defp get_segment_option(options, index), do: Enum.find(options, fn option -> option.segment == index end)
end
