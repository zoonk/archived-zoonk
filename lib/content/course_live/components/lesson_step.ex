# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Content.LessonStep do
  @moduledoc false
  use UneebeeWeb, :html

  alias Uneebee.Content.LessonStep

  attr :step, LessonStep, required: true
  attr :selected, :integer, default: nil

  def lesson_step(assigns) do
    ~H"""
    <section>
      <p class="text-gray-dark whitespace-pre-wrap"><%= @step.content %></p>

      <div :if={@step.image} class="text-gray-dark py-4">
        <img src={@step.image} class="w-1/3" />
      </div>

      <.option_list :if={@selected && @step.options != []} options={@step.options} selected={@selected} />
    </section>
    """
  end

  defp option_list(assigns) do
    ~H"""
    <div>
      <% selected = selected_option(@options, @selected) %>
      <% color = if selected.correct?, do: :success_light, else: :alert_light %>
      <% icon = if selected.correct?, do: "tabler-checks", else: "tabler-alert-square-rounded" %>
      <% default_feedback =
        if selected.correct?, do: dgettext("courses", "Well done!"), else: dgettext("courses", "That's incorrect.") %>
      <% feedback = if selected.feedback, do: selected.feedback, else: default_feedback %>

      <.badge color={color} icon={icon}>
        <%= dgettext("courses", "You selected: %{title}. %{feedback}", title: selected.title, feedback: feedback) %>
      </.badge>

      <.badge :if={not selected.correct?} color={:success_light} icon="tabler-checks">
        <%= dgettext("courses", "Correct answer: %{title}.", title: correct_option(@options).title) %>
      </.badge>
    </div>
    """
  end

  defp selected_option(options, selected_id) do
    Enum.find(options, fn option -> option.id == selected_id end)
  end

  defp correct_option(options), do: Enum.find(options, fn option -> option.correct? end)
end
