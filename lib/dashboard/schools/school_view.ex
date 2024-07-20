defmodule ZoonkWeb.Live.Dashboard.SchoolView do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Organizations

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    %{school: school} = socket.assigns

    current_school = Organizations.get_school!(params["id"])

    unless school.id == current_school.school_id, do: raise(ZoonkWeb.PermissionError, code: :permission_denied)

    user_count = Organizations.get_school_users_count(current_school.id)
    managers = Organizations.list_school_users(current_school.id, role: :manager)

    socket =
      socket
      |> assign(page_title: current_school.name)
      |> assign(:current_school, current_school)
      |> assign(:user_count, user_count)
      |> assign(:managers, managers)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("delete_school", _params, socket) do
    %{current_school: current_school} = socket.assigns

    case Organizations.delete_school(current_school) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, dgettext("orgs", "School deleted"))
          |> push_navigate(to: ~p"/dashboard/schools")

        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "School could not be deleted"))}
    end
  end
end
