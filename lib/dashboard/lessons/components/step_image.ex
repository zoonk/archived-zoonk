# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule ZoonkWeb.Components.Dashboard.StepImage do
  @moduledoc false
  use ZoonkWeb, :html

  alias Zoonk.Content.Course
  alias Zoonk.Content.Lesson
  alias Zoonk.Content.LessonStep
  alias ZoonkWeb.Shared.Storage

  attr :course, Course, required: true
  attr :lesson, Lesson, required: true
  attr :step, LessonStep, required: true

  def step_image(assigns) do
    ~H"""
    <div class="pt-4 pb-8">
      <.link
        :if={@step.image}
        id="step-img-link"
        aria-label={dgettext("orgs", "Edit step image")}
        patch={~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/s/#{@step.order}/image"}
        class="block"
      >
        <img src={Storage.get_url(@step.image)} class="aspect-square w-full object-cover sm:w-[250px]" />
      </.link>

      <.link
        :if={is_nil(@step.image)}
        patch={~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/s/#{@step.order}/image"}
        class="bg-white text-gray-600 shadow aspect-video flex w-full flex-col items-center justify-center rounded-2xl px-4 py-12 text-center xl:w-[386px]"
      >
        <%= dgettext("orgs", "Click to add an image to this step.") %>
      </.link>
    </div>
    """
  end
end
