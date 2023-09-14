# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Input do
  @moduledoc """
  Input components.
  """
  use Phoenix.Component

  import UneebeeWeb.Components.Icon

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.FormField

  @doc """
  Renders an input with label and error messages.

  A `%Form{}` and field name may be passed to the input
  to build input names and error messages, or all the attributes and
  errors may be passed explicitly.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil, doc: "the id of the input"
  attr :name, :any, doc: "the name of the input"
  attr :label, :string, default: nil, doc: "the label of the input"
  attr :value, :any, doc: "the value of the input"
  attr :helper, :string, default: nil, doc: "a helper text to be displayed with the input"

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file hidden month number password
               range radio search select tel text textarea time url week)

  attr :field, FormField, doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: [], doc: "the errors to display for the input"
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :rest, :global, include: ~w(autocomplete cols disabled form max maxlength min minlength
                                   pattern placeholder readonly required rows size step)

  slot :inner_block, doc: "the inner block of the input"

  def input(%{field: %FormField{} = field} = assigns) do
    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox", value: value} = assigns) do
    assigns = assign_new(assigns, :checked, fn -> Form.normalize_value("checkbox", value) end)

    ~H"""
    <div phx-feedback-for={@name} hidden={@type == "hidden"}>
      <label class="text-gray flex items-start gap-4 text-sm" for={@id}>
        <input type="hidden" name={@name} value="false" />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="border-gray-light text-gray-dark rounded focus:ring-0"
          {@rest}
        />
        <span class="flex flex-col gap-2"><span class="font-semibold"><%= @label %></span>
          <span><%= @helper %></span></span>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} hidden={@type == "hidden"}>
      <.label for={@id}><%= @label %></.label>
      <.helper :if={@helper}><%= @helper %></.helper>
      <select
        id={@id}
        name={@name}
        class="border-gray-light mt-1 block w-full rounded-md border bg-white shadow-sm focus:border-gray focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name}>
      <.label for={@id}><%= @label %></.label>
      <.helper :if={@helper}><%= @helper %></.helper>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block min-h-[6rem] w-full rounded-lg border-gray-light py-[7px] px-[11px]",
          "text-gray-dark focus:border-gray focus:outline-none focus:ring-4 focus:ring-gray-dark/5 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-gray-light phx-no-feedback:focus:border-gray phx-no-feedback:focus:ring-gray-dark/5",
          @errors == [] && "border-gray-light focus:border-gray focus:ring-gray-dark/5",
          @errors != [] && "border-alert focus:border-alert focus:ring-alert/10"
        ]}
        {@rest}
      ><%= Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name} hidden={@type == "hidden"}>
      <.label :if={@type != "hidden"} for={@id}><%= @label %></.label>
      <.helper :if={@helper}><%= @helper %></.helper>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg border-gray-light py-[7px] px-[11px]",
          "text-gray-dark focus:outline-none focus:ring-4 sm:text-sm sm:leading-6",
          "phx-no-feedback:border-gray-light phx-no-feedback:focus:border-gray phx-no-feedback:focus:ring-gray-dark/5",
          @errors == [] && "border-gray-light focus:border-gray focus:ring-gray-dark/5",
          @errors != [] && "border-alert focus:border-alert focus:ring-alert/10"
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="text-gray-dark block text-sm font-semibold leading-6"><%= render_slot(@inner_block) %></label>
    """
  end

  @doc """
  Renders a helper text.
  """
  slot :inner_block, required: true

  def helper(assigns) do
    ~H"""
    <span class="text-gray-dark text-sm leading-6"><%= render_slot(@inner_block) %></span>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="text-alert mt-3 flex gap-3 text-sm leading-6 phx-no-feedback:hidden">
      <.icon name="tabler-alert-circle-filled" class="mt-0.5 h-5 w-5 flex-none" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(UneebeeWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(UneebeeWeb.Gettext, "errors", msg, opts)
    end
  end
end
