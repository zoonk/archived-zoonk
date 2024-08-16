defmodule ZoonkWeb.Components.Content.FillStep do
  @moduledoc false
  use ZoonkWeb, :html

  attr :segments, :list, required: true
  attr :selected_segments, :list, required: true

  def fill_step(assigns) do
    ~H"""
    <div id="fill-step" class="flex flex-wrap items-center gap-2">
      <button
        :for={{segment, index} <- Enum.with_index(get_segments(@segments, @selected_segments))}
        type="button"
        disabled={!selectable?(@selected_segments, index)}
        phx-click="remove-segment"
        phx-value-index={index}
        class={["p-2", selectable?(@selected_segments, index) && "semibold rounded-md bg-slate-50"]}
      >
        <%= segment %>
      </button>
    </div>
    """
  end

  defp get_segments(segments, selected) do
    segments
    |> Enum.with_index()
    |> Enum.map(fn {segment, idx} ->
      get_segment(segment, idx, selected)
    end)
  end

  defp get_segment(nil, idx, selected), do: get_segment(Enum.at(selected, idx))
  defp get_segment(segment, _idx, _selected), do: segment

  defp get_segment(nil), do: "_ _ _ _ _ _ _ _"
  defp get_segment(option), do: option.title

  defp selectable?(segments, index), do: !is_nil(Enum.at(segments, index))
end
