# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Content.CourseList do
  @moduledoc false
  use UneebeeWeb, :html

  import Uneebee.Content.Course.Config

  attr :id, :string, required: true
  attr :title, :string, default: nil
  attr :courses, :list, required: true
  attr :my_courses, :boolean, default: false
  attr :empty, :boolean, default: false

  def course_list(assigns) do
    ~H"""
    <section :if={not @empty} class="mb-4">
      <h1 :if={@title} class="text-gray-dark mb-2 font-semibold"><%= @title %></h1>

      <dl id={@id} phx-update="stream" class="grid grid-cols-1 gap-4 sm:grid-cols-2 md:grid-cols-3">
        <.link
          :for={{dom_id, course_data} <- @courses}
          id={dom_id}
          navigate={course_link(course_data, @my_courses)}
          class="card-with-link rounded-2xl border bg-white"
        >
          <% course = if @my_courses, do: course_data, else: course_data.data %>
          <img :if={course.cover} src={course.cover} class="aspect-video w-full rounded-2xl object-cover p-1" />

          <div class="p-4">
            <div class="min-w-0">
              <dt class="text-gray-dark truncate font-bold"><%= course.name %></dt>
              <dd class="text-primary truncate text-xs"><%= course.school.name %></dd>
              <dd class="text-gray line-clamp-2 mt-2 text-sm"><%= course.description %></dd>
            </div>

            <div>
              <.badge icon="tabler-chart-arrows-vertical" class="mt-4"><%= level_label(course.level) %></.badge>

              <.badge :if={course.published? and course.public? and not @my_courses} icon="tabler-user" color={:black_light}>
                <%= course_data.student_count %>
              </.badge>
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
