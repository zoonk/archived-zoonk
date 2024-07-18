# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule ZoonkWeb.Components.Content.CourseList do
  @moduledoc false
  use ZoonkWeb, :html

  alias Zoonk.Content.CourseUtils
  alias Zoonk.Storage.StorageAPI

  attr :id, :string, required: true
  attr :courses, :list, required: true
  attr :my_courses, :boolean, default: false
  attr :empty, :boolean, default: false

  def course_list(assigns) do
    ~H"""
    <dl
      :if={not @empty}
      id={@id}
      phx-update="stream"
      class="grid grid-cols-1 gap-4 3xl:grid-cols-5 4xl:grid-cols-6 5xl:grid-cols-7 6xl:grid-cols-8 7xl:grid-cols-9 sm:grid-cols-2 lg:gap-6 xl:grid-cols-3 xl:gap-8 2xl:grid-cols-4"
    >
      <.link
        :for={{dom_id, course_data} <- @courses}
        id={dom_id}
        navigate={course_link(course_data, @my_courses)}
        class="h-60 shadow hover:shadow-lg rounded-2xl relative focus:outline-offset-4 focus:outline-2 focus:outline-indigo-500"
      >
        <% course = if @my_courses, do: course_data, else: course_data.data %>
        <img :if={course.cover} src={StorageAPI.get_url(course.cover)} class="h-full w-full rounded-2xl object-cover" />
        <div :if={is_nil(course.cover)} class="h-full w-full rounded-2xl bg-gradient-to-br from-pink-50 to-cyan-50" />

        <div class="absolute right-4 bottom-4 left-4 flex min-w-0 flex-col justify-between rounded-2xl bg-white p-4 pb-1 text-sm">
          <div>
            <dt class="truncate font-bold text-gray-700"><%= course.name %></dt>
            <dd class="line-clamp-2 pt-1 text-sm text-gray-500"><%= course.description %></dd>
          </div>

          <div class="mt-4 pb-1">
            <.badge icon="tabler-chart-arrows-vertical"><%= CourseUtils.level_label(course.level) %></.badge>
            <.badge :if={not @my_courses} icon="tabler-user" color={:black}><%= course_data.student_count %></.badge>
          </div>
        </div>
      </.link>
    </dl>
    """
  end

  defp course_link(course, true), do: ~p"/c/#{course.slug}"
  defp course_link(course, false), do: ~p"/c/#{course.data.slug}"
end
