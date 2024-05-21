defmodule ZoonkWeb.Components.Dashboard.OptionList do
  @moduledoc false
  use ZoonkWeb, :live_component

  alias Zoonk.Content
  alias Zoonk.Content.Course
  alias Zoonk.Content.Lesson
  alias Zoonk.Content.LessonStep
  alias Zoonk.Content.StepOption

  attr :action, :atom, default: nil
  attr :course, Course, required: true
  attr :lesson, Lesson, required: true
  attr :option, StepOption, default: nil
  attr :step, LessonStep, required: true

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-base font-semibold leading-6 text-gray-900"><%= dgettext("orgs", "Options") %></h2>

      <h3 class="mt-6 inline text-sm text-gray-500 sm:pr-4 ">
        <%= dgettext("orgs", "These are the options students can select while playing this step.") %>
      </h3>

      <ul class="mt-8 space-y-2">
        <li :for={option <- @step.options} id={"option-#{option.id}"} class="flex items-center gap-2 text-sm">
          <.link
            id={"option-#{option.id}-image-link"}
            aria-label={dgettext("orgs", "Edit image")}
            patch={~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/s/#{@step.order}/o/#{option.id}/image"}
          >
            <.avatar src={option.image} alt={option.title} />
          </.link>

          <.link
            patch={~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/s/#{@step.order}/o/#{option.id}"}
            class={[
              "w-max truncate rounded-2xl border px-2 py-1",
              option.correct? && "bg-teal-50 text-teal-900 border-teal-900",
              not option.correct? && "border-gray-400"
            ]}
          >
            <%= option.title %>
          </.link>

          <% selected_count = round(option_selections_percent(@selections, option)) %>

          <.badge title={dgettext("orgs", "This option was selected %{count}% of the time.", count: selected_count)}>
            <%= selected_count %>%
          </.badge>

          <.icon_button
            icon="tabler-x"
            size={:sm}
            role="button"
            label={dgettext("orgs", "Delete option")}
            data-confirm={gettext("Are you sure?")}
            phx-click="delete-option"
            phx-value-option-id={option.id}
            phx-target={@myself}
          />
        </li>
      </ul>

      <.modal :if={@action == :option} show id="edit-option-modal" on_cancel={JS.patch(~p"/dashboard/c/#{@course.slug}/l/#{@lesson.id}/s/#{@step.order}")}>
        <.simple_form
          for={@option_form}
          title={dgettext("orgs", "Update option")}
          id="option-form"
          phx-change="validate-option"
          phx-target={@myself}
          phx-submit="update-option"
          unstyled
          class="space-y-8"
        >
          <.input type="text" field={@option_form[:title]} label={dgettext("orgs", "Option title")} required />

          <.input
            type="text"
            field={@option_form[:feedback]}
            label={dgettext("orgs", "Option feedback")}
            helper={dgettext("orgs", "Feedback message displayed after a user answers this question. You can provide some additional context on why this is wrong or correct.")}
          />

          <.input
            type="checkbox"
            field={@option_form[:correct?]}
            label={dgettext("orgs", "Is correct?")}
            helper={dgettext("orgs", "Check this option if this is the correct answer.")}
          />

          <:actions>
            <.button type="submit" phx-disable-with={gettext("Saving...")}><%= gettext("Save") %></.button>
          </:actions>
        </.simple_form>
      </.modal>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    changeset = option_changeset(assigns.option)
    selections = Content.count_selections_by_lesson_step(assigns.step.id)

    socket =
      socket
      |> assign(assigns)
      |> assign(option_form: to_form(changeset))
      |> assign(selections: selections)

    {:ok, socket}
  end

  defp option_changeset(nil), do: Content.change_step_option(%StepOption{})
  defp option_changeset(option), do: Content.change_step_option(option)

  defp option_stats(selections, option) do
    stats = Enum.find(selections, fn selection -> selection.option_id == option.id end)
    handle_option_stats(option, stats)
  end

  defp handle_option_stats(option, nil), do: %{option_id: option.id, count: 0}
  defp handle_option_stats(_option, stats), do: stats

  defp total_selections(selections) do
    Enum.reduce(selections, 0, fn selection, acc -> acc + selection.selections end)
  end

  defp option_selections_percent(selections, option) do
    total = total_selections(selections)
    stats = option_stats(selections, option)
    if total > 0, do: stats.selections / total * 100, else: 0
  end

  @impl Phoenix.LiveComponent
  def handle_event("validate-option", %{"step_option" => step_option_params}, socket) do
    changeset = %StepOption{} |> Content.change_step_option(step_option_params) |> Map.put(:action, :validate)
    {:noreply, assign(socket, option_form: to_form(changeset))}
  end

  @impl Phoenix.LiveComponent
  def handle_event("update-option", %{"step_option" => option_params}, socket) do
    %{course: course, lesson: lesson, option: option, step: step} = socket.assigns

    case Content.update_step_option(option, option_params) do
      {:ok, _option} ->
        {:noreply, push_patch(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{step.order}")}

      {:error, _changeset} ->
        {:noreply, put_flash!(socket, :error, dgettext("orgs", "Could not update option!"))}
    end
  end

  @impl Phoenix.LiveComponent
  def handle_event("delete-option", params, socket) do
    %{course: course, lesson: lesson, step: step} = socket.assigns
    option_id = String.to_integer(params["option-id"])

    case Content.delete_step_option(option_id) do
      {:ok, _option} ->
        {:noreply, push_patch(socket, to: ~p"/dashboard/c/#{course.slug}/l/#{lesson.id}/s/#{step.order}")}

      {:error, _changeset} ->
        {:noreply, put_flash!(socket, :error, dgettext("orgs", "Could not delete option!"))}
    end
  end
end
