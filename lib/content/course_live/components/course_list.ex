# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Content.CourseList do
  @moduledoc false
  use UneebeeWeb, :html

  alias Uneebee.Content.CourseUtils

  attr :id, :string, required: true
  attr :title, :string, default: nil
  attr :courses, :list, required: true
  attr :my_courses, :boolean, default: false
  attr :empty, :boolean, default: false

  def course_list(assigns) do
    ~H"""
    <section :if={not @empty}>
      <h1 :if={@title} class="text-gradient mb-2 font-semibold"><%= @title %></h1>

      <dl id={@id} phx-update="stream" class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <.link :for={{dom_id, course_data} <- @courses} id={dom_id} navigate={course_link(course_data, @my_courses)} class="card-with-link flex p-1">
          <% course = if @my_courses, do: course_data, else: course_data.data %>
          <img :if={course.cover} src={course.cover} class="h-24 w-24 rounded-2xl object-cover" />
          <div :if={is_nil(course.cover)} class="bg-gray-light3x h-24 w-24 rounded-2xl" />

          <div class="flex h-full min-w-0 flex-1 flex-col justify-between px-2 text-sm">
            <div>
              <dt class="text-gray-dark truncate font-bold"><%= course.name %></dt>
              <dd class="text-gray line-clamp-2 pt-1 text-sm"><%= course.description %></dd>
            </div>

            <div class="pb-1">
              <.badge icon="tabler-chart-arrows-vertical"><%= CourseUtils.level_label(course.level) %></.badge>
              <.badge :if={not @my_courses} icon="tabler-user" color={:black_light}><%= course_data.student_count %></.badge>
            </div>
          </div>
        </.link>
      </dl>
    </section>
    """
  end

  defp course_link(course, true), do: ~p"/c/#{course.slug}"
  defp course_link(course, false), do: ~p"/c/#{course.data.slug}"
end
