defmodule ZoonkWeb.Components.Upload do
  @moduledoc """
  Reusable file upload component.
  """
  use ZoonkWeb, :live_component

  alias ZoonkWeb.Shared.ImageOptimizer

  attr :current_img, :string, default: nil
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
          <img :if={is_binary(@current_img)} alt={@label} src={get_image_url(@current_img, "thumbnail")} class="w-16 rounded-xl object-cover" />

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
          <p :if={entry.done? and @uploading?} class="text-gray-500"><%= gettext("Processing file...") %></p>
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
      |> assign(:uploading?, false)
      |> allow_upload(
        :file,
        accept: ~w(.jpg .jpeg .png .avif .gif .webp),
        max_entries: 1,
        auto_upload: true,
        progress: &handle_progress/3
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("remove", _params, socket) do
    notify_parent(socket, nil)
    {:noreply, socket}
  end

  defp notify_parent(socket, upload_path) do
    send(self(), {__MODULE__, socket.assigns.id, upload_path})
    :ok
  end

  # Only upload a file to the cloud after the progress is done.
  defp handle_progress(_key, %{done?: true}, socket) do
    file_upload(socket, ImageOptimizer.enabled?())
    {:noreply, assign(socket, uploading?: false)}
  end

  defp handle_progress(_key, _entry, socket) do
    {:noreply, assign(socket, uploading?: true)}
  end

  defp file_upload(socket, true), do: cloud_upload(socket)
  defp file_upload(socket, false), do: local_upload(socket)

  # sobelow_skip ["Traversal.FileModule"]
  defp cloud_upload(socket) do
    result =
      consume_uploaded_entries(socket, :file, fn %{path: path}, entry ->
        byte_content = File.read!(path)
        ImageOptimizer.upload(entry.client_name, byte_content)
      end)

    notify_parent(socket, Enum.at(result, 0))
  end

  defp local_upload(socket) do
    case consume_uploaded_entries(socket, :file, &consume_entry/2) do
      [] -> :ok
      [upload_path] -> notify_parent(socket, upload_path)
    end
  end

  # sobelow_skip ["Traversal.FileModule"]
  defp consume_entry(%{path: path}, _entry) do
    dest = Path.join([:code.priv_dir(:zoonk), "static", "uploads", Path.basename(path)])

    File.cp!(path, dest)
    file_name = Path.basename(dest)

    {:ok, ~p"/uploads/#{file_name}"}
  end

  # Since we only allow uploading one file, we only care about the first entry.
  defp get_entry([]), do: nil
  defp get_entry([entry | _]), do: entry

  defp error_to_string(:too_large), do: dgettext("errors", "Too large")
  defp error_to_string(:not_accepted), do: dgettext("errors", "You have selected an unacceptable file type")
  defp error_to_string(:too_many_files), do: dgettext("errors", "You have selected too many files")
end
