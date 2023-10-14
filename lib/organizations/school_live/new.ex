defmodule UneebeeWeb.Live.Organizations.School.New do
  @moduledoc false
  use UneebeeWeb, :live_view

  alias Uneebee.Organizations
  alias Uneebee.Organizations.School

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    changeset = Organizations.change_school(%School{})

    socket = socket |> assign(page_title: dgettext("orgs", "Create school")) |> assign(form: to_form(changeset))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"school" => school_params}, socket) do
    form =
      %School{}
      |> Organizations.change_school(school_params)
      |> Map.put(:action, :validate)
      |> to_form()

    socket = assign(socket, form: form)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"school" => school_params}, socket) do
    %{current_user: user, host: host} = socket.assigns

    attrs = Map.merge(school_params, %{"created_by_id" => user.id, "custom_domain" => host})

    case Organizations.create_school_and_manager(user, attrs) do
      {:ok, _school} ->
        {:noreply, push_navigate(socket, to: ~p"/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(form: to_form(changeset))
         |> put_flash(:error, dgettext("orgs", "School could not be created"))}
    end
  end
end
