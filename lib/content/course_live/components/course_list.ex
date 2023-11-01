# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Content.CourseList do
  @moduledoc false
  use UneebeeWeb, :html

  alias Uneebee.Content.CourseUtils

  attr :id, :string, required: true
  attr :courses, :list, required: true
  attr :my_courses, :boolean, default: false
  attr :empty, :boolean, default: false

  def course_list(assigns) do
    ~H"""
    <dl :if={not @empty} id={@id} phx-update="stream" class="grid grid-cols-1 gap-4 sm:grid-cols-2">
      <.link :for={{dom_id, course_data} <- @courses} id={dom_id} navigate={course_link(course_data, @my_courses)} class="card-with-link h-60 relative p-1">
        <% course = if @my_courses, do: course_data, else: course_data.data %>
        <img :if={course.cover} src={course.cover} class="h-full w-full rounded-2xl object-cover" />
        <div :if={is_nil(course.cover)} class="from-alert-light3x to-info-light3x h-full w-full rounded-2xl bg-gradient-to-br" />

        <div class="absolute right-4 bottom-4 left-4 flex min-w-0 flex-col justify-between rounded-2xl bg-white p-4 pb-1 text-sm">
          <div>
            <dt class="text-gray-dark truncate font-bold"><%= course.name %></dt>
            <dd class="text-gray line-clamp-2 pt-1 text-sm"><%= course.description %></dd>
          </div>

          <div class="mt-4 pb-1">
            <.badge icon="tabler-chart-arrows-vertical"><%= CourseUtils.level_label(course.level) %></.badge>
            <.badge :if={not @my_courses} icon="tabler-user" color={:black_light}><%= course_data.student_count %></.badge>
          </div>
        </div>
      </.link>
    </dl>
    """
  end

  defp course_link(course, true), do: ~p"/c/#{course.slug}"
  defp course_link(course, false), do: ~p"/c/#{course.data.slug}"
end
