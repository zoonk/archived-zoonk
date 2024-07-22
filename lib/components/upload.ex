defmodule ZoonkWeb.Components.Upload do
  @moduledoc """
  Reusable file upload component.
  """
  use ZoonkWeb, :live_component

  alias Zoonk.Storage
  alias Zoonk.Storage.ImageOptimizer

  attr :current_img, :string, default: nil
  attr :folder, :string, required: true
  attr :label, :string, default: nil
  attr :subtitle, :string, default: nil
  attr :unstyled, :boolean, default: false

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <form id={"upload-form-#{@id}"} class={[@unstyled && "flex flex-col-reverse"]} phx-change="validate" phx-target={@myself} phx-drop-target={@uploads.file.ref}>
      <div class={["flex flex-wrap items-center gap-2", not @unstyled && "top-[57px] sticky bg-gray-50 p-4 sm:flex-nowrap sm:px-6 lg:px-8"]}>
        <h1 :if={not @unstyled} class="text-base font-semibold leading-7 text-gray-900"><%= @label %></h1>

        <div class={["flex gap-2", not @unstyled && "ml-auto", @unstyled && "flex-row-reverse"]}>
          <.button :if={@current_img} id={"remove-#{@id}"} phx-click="remove" phx-target={@myself} icon="tabler-trash" type="button" color={:alert_light}>
            <%= gettext("Remove") %>
          </.button>
        </div>
      </div>

      <% entry = get_entry(@uploads.file.entries) %>

      <div class="container flex flex-col space-y-8">
        <div class="flex items-center space-x-6">
          <img :if={is_binary(@current_img)} alt={@label} src={Storage.get_url(@current_img)} class="w-16 rounded-xl object-cover" />

          <.live_file_input
            upload={@uploads.file}
            class={[
              "block w-full text-sm text-gray-500",
              "file:mr-4 file:py-2 file:px-4",
              "file:rounded-full file:border-0",
              "file:text-sm file:font-semibold",
              "file:bg-indigo-50 file:text-indigo-700",
              "hover:file:bg-indigo-300"
            ]}
          />
        </div>

        <div :if={entry}>
          <p :if={not entry.done?} class="text-gray-500"><%= gettext("Uploading: %{progress}%", progress: entry.progress) %></p>
          <p :for={err <- upload_errors(@uploads.file, entry)} class="text-pink-600"><%= error_to_string(err) %></p>
        </div>
      </div>
    </form>
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    socket =
      socket
      |> allow_upload(
        :file,
        accept: ~w(.jpg .jpeg .png .avif .gif .webp),
        max_entries: 1,
        auto_upload: true,
        external: &presign_upload/2,
        progress: &handle_progress/3
      )
      |> assign(:uploaded_file_key, nil)

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("remove", _params, socket) do
    case Storage.delete_object(socket.assigns.current_img) do
      {:ok, _} ->
        notify_parent(socket, nil)
        {:noreply, socket}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, dgettext("errors", "Failed to remove file"))}
    end
  end

  defp notify_parent(socket, upload_path) do
    send(self(), {__MODULE__, socket.assigns.id, upload_path})
    :ok
  end

  defp presign_upload(entry, socket) do
    {url, key} = Storage.presigned_url(entry, socket.assigns.folder)
    {:ok, %{uploader: "S3", key: key, url: url}, assign(socket, :uploaded_file_key, key)}
  end

  defp handle_progress(_key, %{done?: true}, socket) do
    %{uploaded_file_key: key} = socket.assigns

    # Optimize the image in the background.
    %{key: key} |> ImageOptimizer.new() |> Oban.insert!()

    # Notify the parent component that the upload is done.
    notify_parent(socket, key)

    {:noreply, socket}
  end

  defp handle_progress(_key, _entry, socket) do
    {:noreply, socket}
  end

  # Since we only allow uploading one file, we only care about the first entry.
  defp get_entry([]), do: nil
  defp get_entry([entry | _]), do: entry

  defp error_to_string(:too_large), do: dgettext("errors", "Too large")
  defp error_to_string(:not_accepted), do: dgettext("errors", "You have selected an unacceptable file type")
  defp error_to_string(:too_many_files), do: dgettext("errors", "You have selected too many files")
end
