# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Dashboard.CourseList do
  @moduledoc false
  use UneebeeWeb, :html

  attr :id, :string, required: true
  attr :title, :string, default: nil
  attr :courses, :list, required: true

  def course_list(assigns) do
    ~H"""
    <section class="mb-4">
      <h1 :if={@title} class="text-gray-dark mb-2 font-semibold"><%= @title %></h1>

      <dl id={@id} phx-update="stream" class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <.link :for={{dom_id, course} <- @courses} id={dom_id} navigate={~p"/dashboard/c/#{course.slug}"} class="card-with-link flex rounded-2xl bg-white">
          <img :if={course.cover} src={course.cover} class="w-20 rounded-2xl object-cover p-1" />
          <div :if={is_nil(course.cover)} class="bg-gray-light3x m-1 w-20 rounded-2xl" />

          <div class="min-w-0 p-2 text-sm">
            <div class="min-w-0">
              <dt class="text-gray-dark truncate font-bold"><%= course.name %></dt>
              <dd class="text-gray line-clamp-2"><%= course.description %></dd>
            </div>

            <div :if={not course.published? or not course.public?} class="mt-2">
              <.badge :if={not course.published?} icon="tabler-notes-off" color={:black_light}>
                <%= dgettext("orgs", "Draft") %>
              </.badge>

              <.badge :if={not course.public?} icon="tabler-eye-off" color={:alert_light}>
                <%= dgettext("orgs", "Private") %>
              </.badge>
            </div>
          </div>
        </.link>
      </dl>
    </section>
    """
  end
end
