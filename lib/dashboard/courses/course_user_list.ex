defmodule UneebeeWeb.Live.Dashboard.CourseUserList do
  @moduledoc false
  use UneebeeWeb, :live_view
  use UneebeeWeb.Shared.Paginate, as: :users

  import UneebeeWeb.Components.Dashboard.UserListHeader

  alias Uneebee.Accounts
  alias Uneebee.Accounts.User
  alias Uneebee.Accounts.UserUtils
  alias Uneebee.Content
  alias Uneebee.Content.CourseUtils

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{course: course} = socket.assigns
    user_count = Content.get_course_users_count(course.id)

    socket =
      socket
      |> assign(:page_title, dgettext("orgs", "Users"))
      |> assign(:user_count, user_count)
      |> add_pagination()

    {:ok, socket}
  end

  defp paginate(socket, new_page) when new_page >= 1 do
    %{per_page: per_page, course: course} = socket.assigns
    users = Content.list_course_users(course.id, offset: (new_page - 1) * per_page, limit: per_page)
    paginate(socket, new_page, users)
  end

  @impl Phoenix.LiveView
  def handle_event("add-user", %{"email_or_username" => email_or_username}, socket) do
    user = Accounts.get_user_by_email_or_username(email_or_username)
    handle_add_user(user, socket)
  end

  defp handle_add_user(%User{} = user, socket) do
    %{course: course, current_user: approved_by} = socket.assigns

    attrs = %{role: :student, approved?: true, approved_by_id: approved_by.id, approved_at: DateTime.utc_now()}

    case Content.create_course_user(course, user, attrs) do
      {:ok, _course_user} ->
        {:noreply, push_navigate(socket, to: ~p"/dashboard/c/#{course.slug}/users")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not add user!"))}
    end
  end

  defp handle_add_user(nil, socket) do
    {:noreply, put_flash(socket, :error, dgettext("orgs", "User not found!"))}
  end
end
