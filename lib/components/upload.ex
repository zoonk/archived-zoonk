defmodule UneebeeWeb.Components.Upload do
  @moduledoc """
  Reusable file upload component.
  """
  use UneebeeWeb, :live_component

  alias UneebeeWeb.Shared.CloudStorage

  attr :current_img, :string, default: nil
  attr :label, :string, default: nil
  attr :subtitle, :string, default: nil
  attr :unstyled, :boolean, default: false

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <section class={["h-max space-y-4", not @unstyled && "bg-white p-4 card"]}>
      <% entry = List.first(@uploads.file.entries) %>

      <.header :if={@label}>
        <%= @label %>
        <:subtitle><%= @subtitle %></:subtitle>
      </.header>

      <form id={"upload-form-#{@id}"} phx-submit="save" phx-change="validate" phx-drop-target={@uploads.file.ref} phx-target={@myself} class="flex flex-col space-y-8">
        <div class="flex items-center space-x-6">
          <.live_img_preview :if={entry} entry={entry} class="h-16 rounded-2xl object-cover" />

          <img :if={is_binary(@current_img) and is_nil(entry)} alt={@label} src={@current_img} class="w-16 rounded-xl object-cover" />

          <.live_file_input
            upload={@uploads.file}
            class={[
              "block w-full text-sm text-gray",
              "file:mr-4 file:py-2 file:px-4",
              "file:rounded-full file:border-0",
              "file:text-sm file:font-semibold",
              "file:bg-primary-light3x file:text-primary-dark",
              "hover:file:bg-primary-light"
            ]}
          />
        </div>

        <p :if={entry} class="text-gray text-sm">
          <%= if entry.progress > 0,
            do: gettext("Uploading file: %{progress}% concluded.", progress: entry.progress),
            else: gettext("Click on the save button to upload your file.") %>
        </p>

        <p :for={err <- upload_errors(@uploads.file)}><%= error_to_string(err) %></p>

        <div class="flex gap-2">
          <.button icon="tabler-cloud-upload" type="submit" disabled={is_nil(entry)}>
            <%= gettext("Save") %>
          </.button>

          <.button :if={@current_img} phx-click="remove" phx-target={@myself} icon="tabler-trash" type="button" color={:alert_light} phx-disable-with={gettext("Deleting...")}>
            <%= gettext("Remove") %>
          </.button>
        </div>
      </form>
    </section>
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, upload_opts(socket, internal_storage?())}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("cancel", %{"ref" => ref, "value" => _value}, socket) do
    {:noreply, cancel_upload(socket, :file, ref)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", _params, socket) do
    case consume_uploaded_entries(socket, :file, &consume_entry/2) do
      [] -> :ok
      [upload_path] -> notify_parent(socket, upload_path)
    end

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("remove", _params, socket) do
    notify_parent(socket, nil)
    {:noreply, socket}
  end

  defp notify_parent(socket, upload_path) do
    send(self(), {__MODULE__, socket.assigns.id, upload_path})
    :ok
  end

  # sobelow_skip ["Traversal.FileModule"]
  defp consume_entry(%{path: path}, _entry) do
    dest = Path.join([:code.priv_dir(:uneebee), "static", "uploads", Path.basename(path)])

    File.cp!(path, dest)
    file_name = Path.basename(dest)

    {:ok, ~p"/uploads/#{file_name}"}
  end

  defp consume_entry(%{key: key}, _entry) do
    {:ok, Application.get_env(:uneebee, :cdn)[:url] <> "/" <> key}
  end

  defp presign_upload(entry, socket) do
    %{uploads: uploads} = socket.assigns
    current_timestamp = DateTime.to_unix(DateTime.utc_now(), :second)
    key = "#{current_timestamp}_#{entry.client_name}"

    config = %{region: "auto", access_key_id: CloudStorage.access_key_id(), secret_access_key: CloudStorage.secret_access_key(), url: CloudStorage.bucket_url()}

    {:ok, presigned_url} = CloudStorage.presigned_put(config, key: key, content_type: entry.client_type, max_file_size: uploads[entry.upload_config].max_file_size)

    meta = %{uploader: "S3", key: key, url: presigned_url}

    {:ok, meta, socket}
  end

  defp error_to_string(:too_large), do: dgettext("errors", "Too large")
  defp error_to_string(:too_many_files), do: dgettext("errors", "You have selected too many files")
  defp error_to_string(:not_accepted), do: dgettext("errors", "You have selected an unacceptable file type")

  defp internal_storage?, do: is_nil(CloudStorage.bucket())

  defp upload_opts(socket, true), do: allow_upload(socket, :file, accept: accept_files(), max_entries: 1)
  defp upload_opts(socket, false), do: allow_upload(socket, :file, accept: accept_files(), max_entries: 1, external: &presign_upload/2)

  defp accept_files, do: ~w(.jpg .jpeg .png .avif .gif .webp .svg)
end
