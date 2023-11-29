defmodule UneebeeWeb.Live.Dashboard.CourseUserList do
  @moduledoc false
  use UneebeeWeb, :live_view
  use UneebeeWeb.Shared.Paginate, as: :users

  import UneebeeWeb.Components.Dashboard.UserListHeader

  alias Uneebee.Accounts
  alias Uneebee.Accounts.User
  alias Uneebee.Accounts.UserUtils
  alias Uneebee.Content

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{live_action: role, course: course} = socket.assigns
    user_count = Content.get_course_users_count(course, role)

    socket =
      socket
      |> assign(:page_title, get_page_title(role))
      |> assign(:user_count, user_count)
      |> add_pagination()

    {:ok, socket}
  end

  defp paginate(socket, new_page) when new_page >= 1 do
    %{live_action: role, per_page: per_page, course: course} = socket.assigns
    users = Content.list_course_users_by_role(course, role, offset: (new_page - 1) * per_page, limit: per_page)
    paginate(socket, new_page, users)
  end

  @impl Phoenix.LiveView
  def handle_event("approve", %{"course-user-id" => course_user_id}, socket) do
    %{course: course, current_user: user} = socket.assigns
    approved_by_id = user.id

    case Content.approve_course_user(course_user_id, approved_by_id) do
      {:ok, _course_user} ->
        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "User approved!"))
          |> push_navigate(to: get_user_list_route(socket.assigns.live_action, course.slug))

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not approve user!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("reject", %{"course-user-id" => course_user_id}, socket) do
    %{course: course} = socket.assigns

    case Content.delete_course_user(course_user_id) do
      {:ok, _course_user} ->
        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "User rejected!"))
          |> push_navigate(to: get_user_list_route(socket.assigns.live_action, course.slug))

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not reject user!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("remove", %{"course-user-id" => course_user_id}, socket) do
    %{course: course} = socket.assigns

    case Content.delete_course_user(course_user_id) do
      {:ok, _course_user} ->
        {:noreply, push_navigate(socket, to: get_user_list_route(socket.assigns.live_action, course.slug))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not remove user!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("add-user", %{"email_or_username" => email_or_username}, socket) do
    user = Accounts.get_user_by_email_or_username(email_or_username)
    handle_add_user(user, socket)
  end

  defp handle_add_user(%User{} = user, socket) do
    %{course: course, live_action: role, current_user: approved_by} = socket.assigns

    attrs = %{role: role, approved?: true, approved_by_id: approved_by.id, approved_at: DateTime.utc_now()}

    case Content.create_course_user(course, user, attrs) do
      {:ok, _course_user} ->
        {:noreply, push_navigate(socket, to: get_user_list_route(role, course.slug))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not add user!"))}
    end
  end

  defp handle_add_user(nil, socket) do
    {:noreply, put_flash(socket, :error, dgettext("orgs", "User not found!"))}
  end

  defp get_page_title(:teacher), do: gettext("Teachers")
  defp get_page_title(:student), do: gettext("Students")

  defp get_user_list_route(:teacher, slug), do: ~p"/dashboard/c/#{slug}/teachers"
  defp get_user_list_route(:student, slug), do: ~p"/dashboard/c/#{slug}/students"

  defp get_add_link_label(:teacher), do: dgettext("orgs", "Add teacher")
  defp get_add_link_label(:student), do: dgettext("orgs", "Add student")
end
