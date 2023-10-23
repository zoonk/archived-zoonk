# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule UneebeeWeb.Components.Progress do
  @moduledoc false
  use Phoenix.Component

  attr :total, :integer, required: true
  attr :current, :integer, required: true

  def progress(assigns) do
    ~H"""
    <div class="border-gray-light2x flex w-full gap-1 rounded-2xl border p-2">
      <% steps = Enum.map(1..@total, fn order -> order end) %>
      <div
        :for={step <- steps}
        class={[
          "rounded-2xl w-full h-4 flex-1",
          step <= @current && "bg-success-light",
          step > @current && "bg-gray-light3x"
        ]}
      />
    </div>
    """
  end
end
