defmodule ZoonkWeb.Components.Content.FillOptions do
  @moduledoc false
  use ZoonkWeb, :html

  attr :options, :list, required: true
  attr :selected_segments, :list, required: true

  def fill_options(assigns) do
    ~H"""
    <div class="mt-8 flex flex-wrap gap-2">
      <button
        :for={option <- @options}
        disabled={disabled?(option, @selected_segments)}
        type="button"
        phx-click="select-fill-option"
        phx-value-option-id={option.id}
        class={[
          "rounded-lg bg-white p-4 text-slate-700 shadow-md hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-slate-400",
          disabled?(option, @selected_segments) && "cursor-not-allowed opacity-50"
        ]}
      >
        <%= option.title %>
      </button>
    </div>
    """
  end

  def disabled?(option, selected_segments), do: Enum.member?(selected_segments, option)
end
