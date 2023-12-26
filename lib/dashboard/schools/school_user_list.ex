defmodule UneebeeWeb.Live.Dashboard.SchoolUserList do
  @moduledoc false
  use UneebeeWeb, :live_view
  use UneebeeWeb.Shared.Paginate, as: :users

  import UneebeeWeb.Components.Dashboard.UserListHeader

  alias Uneebee.Accounts
  alias Uneebee.Accounts.User
  alias Uneebee.Accounts.UserUtils
  alias Uneebee.Organizations
  alias Uneebee.Organizations.SchoolUtils

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{school: school} = socket.assigns
    user_count = Organizations.get_school_users_count(school.id)
    can_demote_user? = user_count > 1

    socket =
      socket
      |> assign(:can_demote_user?, can_demote_user?)
      |> assign(:user_count, user_count)
      |> add_pagination()

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    %{live_action: live_action, school: school} = socket.assigns

    socket =
      socket
      |> assign(:page_title, page_title(live_action))
      |> assign(:search_results, search_users(school, params["term"]))

    {:noreply, socket}
  end

  defp paginate(socket, new_page) when new_page >= 1 do
    %{per_page: per_page, school: school} = socket.assigns
    users = Organizations.list_school_users(school.id, offset: (new_page - 1) * per_page, limit: per_page)
    paginate(socket, new_page, users)
  end

  @impl Phoenix.LiveView
  def handle_event("add-user", %{"email_or_username" => email_or_username, "role" => role}, socket) do
    user = Accounts.get_user_by_email_or_username(email_or_username)
    handle_add_user(user, role, socket)
  end

  def handle_event("search", %{"term" => search_term}, socket) do
    {:noreply, push_patch(socket, to: ~p"/dashboard/users/search?term=#{search_term}")}
  end

  defp handle_add_user(%User{} = user, role, socket) do
    %{school: school, current_user: approved_by} = socket.assigns

    attrs = %{role: role, approved?: true, approved_by_id: approved_by.id, approved_at: DateTime.utc_now()}

    case Organizations.create_school_user(school, user, attrs) do
      {:ok, _school_user} ->
        {:noreply, push_navigate(socket, to: ~p"/dashboard/users")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not add user!"))}
    end
  end

  defp handle_add_user(nil, _role, socket) do
    {:noreply, put_flash(socket, :error, dgettext("orgs", "User not found!"))}
  end

  defp page_title(:search), do: dgettext("orgs", "Search users")
  defp page_title(_live_action), do: dgettext("orgs", "Users")

  defp search_users(_school, nil), do: []
  defp search_users(school, term), do: Organizations.search_school_users(school.id, term)
end
