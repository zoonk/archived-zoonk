# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Content.LessonStep do
  @moduledoc false
  use UneebeeWeb, :html

  alias Uneebee.Content.LessonStep
  alias Uneebee.Content.StepOption

  attr :step, LessonStep, required: true
  attr :selected, StepOption, default: nil

  def lesson_step(assigns) do
    ~H"""
    <section>
      <p class="text-gray-dark whitespace-pre-wrap py-4"><%= @step.content %></p>

      <div :if={@step.image} class="text-gray-dark py-4">
        <img src={@step.image} class="w-full sm:w-1/3" />
      </div>
    </section>
    """
  end

  attr :selected, StepOption, default: nil
  attr :options, :list, required: true

  def feedback_option(assigns) do
    ~H"""
    <div :if={@selected} class="min-w-0 py-4">
      <% icon = if @selected.correct?, do: "tabler-checks", else: "tabler-alert-square-rounded" %>

      <% default_feedback =
        if @selected.correct?, do: dgettext("courses", "Well done!"), else: dgettext("courses", "That's incorrect.") %>

      <% feedback = if @selected.feedback, do: @selected.feedback, else: default_feedback %>

      <div
        role="alert"
        class={[
          "py-2 px-4 rounded-lg items-center fixed right-4 left-4 sm:sticky sm:w-full font-bold text-sm bottom-[72px] flex gap-2",
          @selected.correct? && "bg-success-light3x text-success-dark2x",
          not @selected.correct? && "bg-alert-light3x text-alert-dark2x"
        ]}
      >
        <.icon name={icon} class="h-3 w-3" /> <%= feedback %>
      </div>
    </div>
    """
  end
end
