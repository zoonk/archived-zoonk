defmodule ZoonkWeb.Components.Dashboard.StepFill do
  @moduledoc false
  use ZoonkWeb, :live_component

  alias Zoonk.Content

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div id="segments" class="flex flex-wrap items-center gap-2">
      <.link
        :for={{segment, index} <- Enum.with_index(@segments)}
        patch={@segment_link.(index)}
        class={["bg-white p-2 rounded-md shadow-sm", is_nil(segment) && "semibold text-teal-500"]}
      >
        <%= get_segment(segment, index, @options) %>
      </.link>

      <button
        type="button"
        phx-click="add_segment"
        phx-target={@myself}
        class="flex h-8 w-8 items-center justify-center rounded-full bg-teal-100 text-teal-900 hover:bg-teal-200 focus:outline-none focus:ring-2 focus:ring-teal-500"
      >
        <span class="sr-only"><%= dgettext("orgs", "Add segment") %></span> +
      </button>
    </div>
    """
  end

  defp get_segment(nil, index, options), do: get_segment_option(options, index).title
  defp get_segment(segment, _idx, _options), do: segment

  defp get_segment_option(options, index), do: Enum.find(options, fn option -> option.segment == index end)

  @impl Phoenix.LiveComponent
  def handle_event("add_segment", _params, socket) do
    case Content.add_segment_to_lesson_step(socket.assigns.step_id) do
      {:ok, lesson_step} ->
        {:noreply, assign(socket, segments: lesson_step.segments)}

      {:error, changeset} ->
        Sentry.Context.set_extra_context(%{changeset: changeset.errors, step_id: socket.assigns.step_id})
        Sentry.capture_message("Unable to add segment.")
        {:noreply, put_flash!(socket, :error, dgettext("errors", "Unable to add segment. Please, contact support."))}
    end
  end
end
