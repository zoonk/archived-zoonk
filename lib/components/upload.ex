defmodule UneebeeWeb.Components.Upload do
  @moduledoc """
  Reusable file upload component.
  """
  use UneebeeWeb, :live_component

  alias UneebeeWeb.Shared.ImageOptimizer

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
      </div>
    </form>
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, allow_upload(socket, :file, accept: ~w(image/*), max_entries: 1, max_file_size: 2_056_392, auto_upload: true, progress: &handle_progress/3)}
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

  defp handle_progress(_image_key, entry, socket) do
    if entry.done? do
      if ImageOptimizer.enabled?(), do: cloud_upload(socket), else: local_upload(socket)
      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

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
    dest = Path.join([:code.priv_dir(:uneebee), "static", "uploads", Path.basename(path)])

    File.cp!(path, dest)
    file_name = Path.basename(dest)

    {:ok, ~p"/uploads/#{file_name}"}
  end
end
