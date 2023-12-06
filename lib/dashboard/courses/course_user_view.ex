defmodule UneebeeWeb.Live.Dashboard.CourseUserView do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Accounts.UserUtils
  alias Uneebee.Content
  alias Uneebee.Content.CourseUtils

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    %{course: course} = socket.assigns

    course_user = Content.get_course_user_by_id(course.id, params["user_id"], preload: :user)

    # Prevent from viewing users who aren't enrolled in the course
    if is_nil(course_user), do: raise(UneebeeWeb.PermissionError, code: :not_enrolled)

    full_name = UserUtils.full_name(course_user.user)
    lessons = Content.list_published_lessons(course, course_user.user, selections?: true)

    socket =
      socket
      |> assign(:page_title, full_name)
      |> assign(:lessons, lessons)
      |> assign(:course_user, course_user)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("approve", _params, socket) do
    %{current_user: current_user, course_user: course_user} = socket.assigns

    case Content.approve_course_user(course_user.id, current_user.id) do
      {:ok, updated_cu} ->
        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "User approved!"))
          |> assign(:course_user, Map.merge(updated_cu, %{user: course_user.user}))

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not approve user!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("reject", _params, socket) do
    %{course: course, course_user: course_user} = socket.assigns

    case Content.delete_course_user(course_user.id) do
      {:ok, _course_user} ->
        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "User rejected!"))
          |> push_navigate(to: ~p"/dashboard/c/#{course.slug}/users")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not reject user!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("remove", _params, socket) do
    %{course: course, course_user: course_user} = socket.assigns

    case Content.delete_course_user(course_user.id) do
      {:ok, _course_user} ->
        {:noreply, push_navigate(socket, to: ~p"/dashboard/c/#{course.slug}/users")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not remove user!"))}
    end
  end
end
