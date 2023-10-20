# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Content.CourseList do
  @moduledoc false
  use UneebeeWeb, :html

  attr :id, :string, required: true
  attr :title, :string, default: nil
  attr :courses, :list, required: true
  attr :my_courses, :boolean, default: false
  attr :empty, :boolean, default: false

  def course_list(assigns) do
    ~H"""
    <section :if={not @empty} class="mb-4">
      <h1 :if={@title} class="text-gray-dark mb-2 font-semibold"><%= @title %></h1>

      <dl id={@id} phx-update="stream" class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <.link :for={{dom_id, course_data} <- @courses} id={dom_id} navigate={course_link(course_data, @my_courses)} class="card-with-link flex rounded-2xl border bg-white">
          <% course = if @my_courses, do: course_data, else: course_data.data %>
          <img :if={course.cover} src={course.cover} class="w-20 rounded-2xl object-cover p-1" />
          <div :if={is_nil(course.cover)} class="bg-gray-light3x w-20 rounded-2xl border-2 border-white p-1" />

          <div class="min-w-0 p-2 text-sm">
            <dt class="text-gray-dark truncate font-bold"><%= course.name %></dt>
            <dd class="text-gray line-clamp-2 text-sm"><%= course.description %></dd>
          </div>
        </.link>
      </dl>
    </section>
    """
  end

  defp course_link(course, true), do: ~p"/c/#{course.slug}"
  defp course_link(course, false), do: ~p"/c/#{course.data.slug}"
end
