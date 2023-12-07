defmodule UneebeeWeb.Live.Dashboard.SchoolUserView do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Accounts.UserUtils
  alias Uneebee.Organizations
  alias Uneebee.Organizations.SchoolUtils

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    %{school: school} = socket.assigns

    school_user = Organizations.get_school_user(school.slug, params["username"], preload: :user)

    # Prevent from viewing users who aren't enrolled in this school.
    if is_nil(school_user), do: raise(UneebeeWeb.PermissionError, code: :not_enrolled)

    full_name = UserUtils.full_name(school_user.user)

    socket =
      socket
      |> assign(:page_title, full_name)
      |> assign(:school_user, school_user)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("approve", _params, socket) do
    %{school_user: school_user, current_user: user} = socket.assigns

    case Organizations.approve_school_user(school_user.id, user.id) do
      {:ok, updated_su} ->
        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "User approved!"))
          |> assign(:school_user, Map.merge(updated_su, %{user: user}))

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not approve user!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("reject", _params, socket) do
    %{school_user: school_user} = socket.assigns

    case Organizations.delete_school_user(school_user.id) do
      {:ok, _school_user} ->
        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "User rejected!"))
          |> push_navigate(to: ~p"/dashboard/users")

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not reject user!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("remove", _params, socket) do
    %{school_user: school_user} = socket.assigns

    case Organizations.delete_school_user(school_user.id) do
      {:ok, _school_user} ->
        {:noreply, push_navigate(socket, to: ~p"/dashboard/users")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not remove user!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("toggle-analytics", _params, socket) do
    %{school_user: school_user} = socket.assigns

    case Organizations.update_school_user(school_user.id, %{analytics?: !school_user.analytics?}) do
      {:ok, updated_su} ->
        {:noreply, assign(socket, :school_user, Map.merge(updated_su, %{user: school_user.user}))}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not toggle analytics tracking!"))}
    end
  end
end
