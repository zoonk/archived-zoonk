# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Content.LessonProgress do
  @moduledoc false
  use UneebeeWeb, :html

  attr :total, :integer, required: true
  attr :current, :integer, required: true

  def lesson_progress(assigns) do
    ~H"""
    <div class="bg-white/90 sticky top-4 flex w-full gap-1 rounded-2xl p-2 shadow backdrop-blur-md">
      <% steps = Enum.map(1..@total, fn order -> order end) %>
      <div
        :for={step <- steps}
        class={["rounded-2xl w-full h-4 flex-1", step <= @current && "bg-success", step > @current && "bg-gray-light3x"]}
      />
    </div>
    """
  end
end
