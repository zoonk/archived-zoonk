defmodule ZoonkWeb.Live.Dashboard.SchoolEdit do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Organizations
  alias Zoonk.Storage
  alias ZoonkWeb.Components.DeleteItem
  alias ZoonkWeb.Components.Upload

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    school = socket.assigns.school
    changeset = Organizations.change_school(school)

    socket =
      socket
      |> assign(page_title: get_page_title(socket.assigns.live_action))
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"school" => school_params}, socket) do
    changeset =
      socket.assigns.school
      |> Organizations.change_school(school_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"school" => school_params}, socket) do
    %{school: school} = socket.assigns

    slug_changed? = school_params["slug"] != school.slug

    case Organizations.update_school(school, school_params) do
      {:ok, _school} ->
        {:noreply, maybe_redirect(socket, slug_changed?, school_params["slug"])}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({Upload, :school_logo, new_path}, socket) do
    case Organizations.update_school(socket.assigns.school, %{logo: new_path}) do
      {:ok, school} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("orgs", "Logo updated successfully!"))
         |> assign(school: school)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not update logo!"))}
    end
  end

  def handle_info({Upload, :school_icon, new_path}, socket) do
    case Organizations.update_school(socket.assigns.school, %{icon: new_path}) do
      {:ok, school} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("orgs", "Icon updated successfully!"))
         |> assign(school: school)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "Could not update icon!"))}
    end
  end

  @impl Phoenix.LiveView
  def handle_info({DeleteItem}, socket) do
    %{app: app, school: school} = socket.assigns

    case Organizations.delete_school(school) do
      {:ok, _school} ->
        {:noreply, redirect(socket, external: "https://#{app.custom_domain}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, dgettext("orgs", "School could not be deleted"))}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp get_page_title(:settings), do: gettext("Settings")
  defp get_page_title(:logo), do: gettext("Logo")
  defp get_page_title(:delete), do: gettext("Delete")
  defp get_page_title(:icon), do: gettext("Icon")

  defp maybe_redirect(socket, false, _new_slug), do: put_flash(socket, :info, dgettext("orgs", "School updated successfully"))
  defp maybe_redirect(socket, true, _new_slug) when is_nil(socket.assigns.school.school_id), do: put_flash(socket, :info, dgettext("orgs", "School updated successfully"))
  defp maybe_redirect(socket, true, new_slug), do: redirect(socket, external: "https://#{new_slug}.#{socket.assigns.app.custom_domain}/dashboard/edit/settings")
end
