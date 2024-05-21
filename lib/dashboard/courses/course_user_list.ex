defmodule ZoonkWeb.Live.Dashboard.CourseUserList do
  @moduledoc false
  use ZoonkWeb, :live_view
  use ZoonkWeb.Shared.Paginate, as: :users

  import ZoonkWeb.Components.Dashboard.UserListHeader

  alias Zoonk.Accounts
  alias Zoonk.Accounts.User
  alias Zoonk.Accounts.UserUtils
  alias Zoonk.Content
  alias Zoonk.Content.CourseUtils

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{course: course} = socket.assigns
    user_count = Content.get_course_users_count(course.id)

    socket =
      socket
      |> assign(:user_count, user_count)
      |> add_pagination()

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    %{live_action: live_action, course: course} = socket.assigns

    socket =
      socket
      |> assign(:page_title, page_title(live_action))
      |> assign(:search_results, search_users(course, params["term"]))

    {:noreply, socket}
  end

  defp paginate(socket, new_page) when new_page >= 1 do
    %{per_page: per_page, course: course} = socket.assigns
    users = Content.list_course_users(course.id, offset: (new_page - 1) * per_page, limit: per_page)
    paginate(socket, new_page, users)
  end

  @impl Phoenix.LiveView
  def handle_event("add-user", %{"email_or_username" => email_or_username, "role" => role}, socket) do
    user = Accounts.get_user_by_email_or_username(email_or_username)
    handle_add_user(user, role, socket)
  end

  def handle_event("search", %{"term" => search_term}, socket) do
    %{course: course} = socket.assigns
    {:noreply, push_patch(socket, to: ~p"/dashboard/c/#{course.slug}/users/search?term=#{search_term}")}
  end

  defp handle_add_user(%User{} = user, role, socket) do
    %{course: course, current_user: approved_by} = socket.assigns

    attrs = %{role: role, approved?: true, approved_by_id: approved_by.id, approved_at: DateTime.utc_now()}

    case Content.create_course_user(course, user, attrs) do
      {:ok, _course_user} ->
        {:noreply, push_navigate(socket, to: ~p"/dashboard/c/#{course.slug}/users")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not add user!"))}
    end
  end

  defp handle_add_user(nil, _role, socket) do
    {:noreply, put_flash(socket, :error, dgettext("orgs", "User not found!"))}
  end

  defp page_title(:search), do: dgettext("orgs", "Search users")
  defp page_title(_live_action), do: dgettext("orgs", "Users")

  defp search_users(_course, nil), do: []
  defp search_users(course, term), do: Content.search_course_users(course.id, term)
end
