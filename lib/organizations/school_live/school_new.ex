defmodule UneebeeWeb.Live.SchoolNew do
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
    %{current_user: user, host: host, app: app} = socket.assigns

    domain = if is_nil(app), do: host
    school_id = if is_nil(app), do: nil, else: app.id
    public? = is_nil(school_id)

    attrs = Map.merge(school_params, %{"created_by_id" => user.id, "custom_domain" => domain, "school_id" => school_id, "public?" => public?})

    case Organizations.create_school_and_manager(user, attrs) do
      {:ok, new_school} ->
        {:noreply, redirect_to_dashboard(socket, new_school, app)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(form: to_form(changeset))
         |> put_flash(:error, dgettext("orgs", "School could not be created"))}
    end
  end

  defp school_kind_options do
    [{dgettext("orgs", "White label"), "white_label"}, {dgettext("orgs", "SaaS"), "saas"}, {dgettext("orgs", "Marketplace"), "marketplace"}]
  end

  defp redirect_to_dashboard(socket, _new_school, nil), do: redirect(socket, to: ~p"/dashboard")

  defp redirect_to_dashboard(socket, %School{} = new_school, %School{} = app), do: redirect(socket, external: "https://#{new_school.slug}.#{app.custom_domain}/dashboard")
end
