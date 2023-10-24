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
    <section class="bg-gray-light3x text-gray-dark2x rounded-3xl p-4">
      <p class="whitespace-pre-wrap"><%= @step.content %></p>
    </section>

    <div :if={@step.image} class="flex w-full justify-center py-2">
      <img src={@step.image} class="aspect-video w-3/4 object-cover" />
    </div>
    """
  end

  attr :selected, StepOption, default: nil
  attr :options, :list, required: true

  def feedback_option(assigns) do
    ~H"""
    <div :if={@selected} class="flex items-center gap-2 text-lg font-semibold">
      <% icon = if @selected.correct?, do: "tabler-checks", else: "tabler-alert-square-rounded" %>

      <% default_feedback =
        if @selected.correct?, do: dgettext("courses", "Well done!"), else: dgettext("courses", "That's incorrect.") %>

      <% feedback = if @selected.feedback, do: @selected.feedback, else: default_feedback %>

      <.icon name={icon} /> <%= feedback %>
    </div>
    """
  end
end
