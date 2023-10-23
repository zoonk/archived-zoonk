# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule UneebeeWeb.Components.Progress do
  @moduledoc false
  use Phoenix.Component

  @max 40

  attr :total, :integer, required: true
  attr :current, :integer, required: true

  def progress(assigns) do
    ~H"""
    <div class="border-gray-light2x flex w-full gap-1 rounded-2xl border p-2">
      <% total = calculate_total(@total) %>
      <% current = calculate_current(@current, @total) %>
      <% steps = Enum.map(1..total, fn order -> order end) %>
      <div
        :for={step <- steps}
        class={[
          "rounded-2xl w-full h-4 flex-1",
          step <= current && "bg-success-light",
          step > current && "bg-gray-light3x"
        ]}
      />
    </div>
    """
  end

  defp calculate_total(total) when total > @max, do: @max
  defp calculate_total(total), do: total

  defp calculate_current(current, total) when total <= @max, do: current
  defp calculate_current(current, total), do: (current * (@max / total)) |> round() |> max(1)
end
