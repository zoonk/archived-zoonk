# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule ZoonkWeb.Components.Content.LessonStep do
  @moduledoc false
  use ZoonkWeb, :html

  alias Zoonk.Content.LessonStep
  alias Zoonk.Content.StepOption
  alias Zoonk.Storage.StorageAPI
  alias ZoonkWeb.Shared.YouTube

  attr :step, LessonStep, required: true
  attr :selected, StepOption, default: nil

  def lesson_step(assigns) do
    ~H"""
    <div class="flex w-full flex-col items-center justify-center gap-4">
      <img :if={@step.image} src={StorageAPI.get_url(@step.image)} class="w-full" />

      <blockquote class="w-fit rounded-2xl bg-gray-50 p-4 text-sm leading-6 text-gray-900 sm:text-lg">
        <p><%= YouTube.remove_from_string(@step.content) %></p>
      </blockquote>

      <.youtube content={@step.content} />
    </div>
    """
  end

  attr :selected, StepOption, default: nil
  attr :options, :list, required: true

  def feedback_option(assigns) do
    ~H"""
    <div :if={@selected} class="flex items-center gap-4 sm:gap-8">
      <% icon = if @selected.correct?, do: "tabler-checks", else: "tabler-x" %>

      <% default_feedback =
        if @selected.correct?, do: dgettext("courses", "Well done!"), else: dgettext("courses", "That's incorrect.") %>

      <div class="flex h-8 w-8 shrink-0 flex-col items-center justify-center rounded-full bg-white sm:h-12 sm:w-12">
        <.icon
          name={icon}
          class={[
            "sm:w-8 sm:h-8",
            @selected.correct? && "text-teal-700",
            not @selected.correct? && "text-pink-700"
          ]}
        />
      </div>

      <div class="leading-6" role="alert">
        <h3 class="text-md font-bold sm:text-lg"><%= default_feedback %></h3>
        <h4 :if={@selected.feedback} class="text-xs sm:text-sm"><%= @selected.feedback %></h4>
      </div>
    </div>
    """
  end
end
