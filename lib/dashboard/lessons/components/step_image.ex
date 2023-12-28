# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Dashboard.StepImage do
  @moduledoc false
  use UneebeeWeb, :html

  alias Uneebee.Content.Course
  alias Uneebee.Content.Lesson
  alias Uneebee.Content.LessonStep

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
        <img src={get_image_url(@step.image, "lessonStep")} class="aspect-square w-full object-cover sm:w-[250px]" />
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
