defmodule UneebeeWeb.Live.Dashboard.UserList do
  @moduledoc false
  use UneebeeWeb, :live_view
  use UneebeeWeb.Shared.Paginate, as: :users

  import UneebeeWeb.Components.Dashboard.UserListHeader

  alias Uneebee.Accounts
  alias Uneebee.Accounts.User
  alias Uneebee.Accounts.UserUtils
  alias Uneebee.Organizations
  alias Uneebee.Organizations.School
  alias UneebeeWeb.Shared.Utilities

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{live_action: role, school: school} = socket.assigns
    user_count = Organizations.get_school_users_count(school, role)
    can_demote_user? = user_count > 1

    socket =
      socket
      |> assign(:page_title, get_page_title(role))
      |> assign(:can_demote_user?, can_demote_user?)
      |> assign(:user_count, user_count)
      |> add_pagination()

    {:ok, socket}
  end

  defp paginate(socket, new_page) when new_page >= 1 do
    %{live_action: role, per_page: per_page, school: school} = socket.assigns
    users = Organizations.list_school_users_by_role(school, role, offset: (new_page - 1) * per_page, limit: per_page)
    paginate(socket, new_page, users)
  end

  @impl Phoenix.LiveView
  def handle_event("approve", %{"school-user-id" => school_user_id}, socket) do
    approved_by_id = socket.assigns.current_user.id

    case Organizations.approve_school_user(school_user_id, approved_by_id) do
      {:ok, _school_user} ->
        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "User approved!"))
          |> push_navigate(to: get_user_list_route(socket.assigns.live_action))

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not approve user!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("reject", %{"school-user-id" => school_user_id}, socket) do
    case Organizations.delete_school_user(school_user_id) do
      {:ok, _school_user} ->
        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "User rejected!"))
          |> push_navigate(to: get_user_list_route(socket.assigns.live_action))

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not reject user!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("remove", %{"school-user-id" => school_user_id}, socket) do
    case Organizations.delete_school_user(school_user_id) do
      {:ok, _school_user} ->
        {:noreply, push_navigate(socket, to: get_user_list_route(socket.assigns.live_action))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not remove user!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("toggle-analytics", %{"school-user-id" => school_user_id, "analytics" => analytics?}, socket) do
    case Organizations.update_school_user(school_user_id, %{analytics?: !Utilities.string_to_boolean(analytics?)}) do
      {:ok, _school_user} ->
        {:noreply, push_navigate(socket, to: get_user_list_route(socket.assigns.live_action))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not toggle analytics tracking!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("add-user", %{"email_or_username" => email_or_username}, socket) do
    user = Accounts.get_user_by_email_or_username(email_or_username)
    handle_add_user(user, socket)
  end

  defp handle_add_user(%User{} = user, socket) do
    %{school: school, live_action: role, current_user: approved_by} = socket.assigns

    attrs = %{role: role, approved?: true, approved_by_id: approved_by.id, approved_at: DateTime.utc_now()}

    case Organizations.create_school_user(school, user, attrs) do
      {:ok, _school_user} ->
        {:noreply, push_navigate(socket, to: get_user_list_route(role))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not add user!"))}
    end
  end

  defp handle_add_user(nil, socket) do
    {:noreply, put_flash(socket, :error, dgettext("orgs", "User not found!"))}
  end

  defp get_user_list_route(:manager), do: ~p"/dashboard/managers"
  defp get_user_list_route(:teacher), do: ~p"/dashboard/teachers"
  defp get_user_list_route(:student), do: ~p"/dashboard/students"

  defp get_page_title(:manager), do: gettext("Managers")
  defp get_page_title(:teacher), do: gettext("Teachers")
  defp get_page_title(:student), do: gettext("Students")

  defp get_add_link_label(:manager), do: dgettext("orgs", "Add manager")
  defp get_add_link_label(:teacher), do: dgettext("orgs", "Add teacher")
  defp get_add_link_label(:student), do: dgettext("orgs", "Add student")

  defp edit_analytics?(%School{} = school), do: is_nil(school.school_id)
end
