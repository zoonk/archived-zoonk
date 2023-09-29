defmodule UneebeeWeb.Live.Dashboard.UserList do
  @moduledoc false
  use UneebeeWeb, :live_view

  import UneebeeWeb.Shared.Accounts

  alias Uneebee.Accounts
  alias Uneebee.Accounts.User
  alias Uneebee.Organizations

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    role = socket.assigns.live_action
    school = socket.assigns.school
    users = Organizations.list_school_users_by_role(school, role)
    can_demote_user? = length(users) > 1

    socket =
      socket
      |> assign(:page_title, get_page_title(role))
      |> stream(:users, users)
      |> assign(:can_demote_user?, can_demote_user?)

    {:ok, socket}
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
        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "User removed!"))
          |> push_navigate(to: get_user_list_route(socket.assigns.live_action))

        {:noreply, socket}

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
    %{school: school, live_action: role, current_user: approved_by} = socket.assigns

    attrs = %{role: role, approved?: true, approved_by_id: approved_by.id, approved_at: DateTime.utc_now()}

    case Organizations.create_school_user(school, user, attrs) do
      {:ok, _school_user} ->
        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "User added!"))
          |> push_navigate(to: get_user_list_route(role))

        {:noreply, socket}

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
end
