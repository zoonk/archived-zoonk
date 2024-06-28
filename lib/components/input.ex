# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule ZoonkWeb.Components.Input do
  @moduledoc """
  Input components.
  """
  use Phoenix.Component

  import ZoonkWeb.Components.Icon

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
  attr :mt, :boolean, default: true, doc: "whether to add a top margin to the input"
  attr :aria_describedby, :string, default: nil, doc: "the aria-describedby attribute for the input"

  attr :type, :string, default: "text", values: ~w(checkbox color date datetime-local email file hidden month number password
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
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []
    aria_describedby = if errors != [], do: "#{field.id}-error"

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign(:aria_describedby, aria_describedby)
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns = assign_new(assigns, :checked, fn -> Form.normalize_value("checkbox", assigns[:value]) end)

    ~H"""
    <div hidden={@type == "hidden"}>
      <label class="flex items-start gap-2 text-sm text-gray-700 disabled:opacity-10" for={@id}>
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          aria-describedby={@aria_describedby}
          class="peer rounded border-gray-200 text-gray-700 focus:ring-0"
          {@rest}
        />
        <span class="flex flex-col gap-2 peer-disabled:cursor-not-allowed peer-disabled:opacity-30"><span class="font-semibold"><%= @label %></span>
          <span class="text-gray-500"><%= @helper %></span></span>
      </label>

      <div id={@aria_describedby} role="alert">
        <.error :for={msg <- @errors}><%= msg %></.error>
      </div>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div hidden={@type == "hidden"}>
      <.label for={@id}><%= @label %></.label>
      <.helper :if={@helper}><%= @helper %></.helper>
      <select
        id={@id}
        name={@name}
        class={["block w-full rounded-md border border-gray-200 bg-white text-gray-900 focus:border-indigo-500 focus:ring-0 sm:text-sm", @mt && "mt-2"]}
        multiple={@multiple}
        aria-describedby={@aria_describedby}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Form.options_for_select(@options, @value) %>
      </select>

      <div id={@aria_describedby} role="alert">
        <.error :for={msg <- @errors}><%= msg %></.error>
      </div>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <.label for={@id}><%= @label %></.label>
      <.helper :if={@helper}><%= @helper %></.helper>
      <textarea
        id={@id}
        name={@name}
        aria-describedby={@aria_describedby}
        class={[
          "min-h-[6rem] py-[7px] px-[11px] block w-full rounded-lg",
          "text-gray-700 focus:ring-gray-700/5 focus:border-indigo-500 focus:outline-none focus:ring-4 sm:text-sm sm:leading-6",
          @mt && "mt-2",
          @errors == [] && "border-gray-200 focus:ring-gray-700/5 focus:border-indigo-500",
          @errors != [] && "border-pink-500 focus:ring-pink-500/10 focus:border-pink-500"
        ]}
        {@rest}
      ><%= Form.normalize_value("textarea", @value) %></textarea>

      <div id={@aria_describedby} role="alert">
        <.error :for={msg <- @errors}><%= msg %></.error>
      </div>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div hidden={@type == "hidden"}>
      <.label :if={@type != "hidden"} for={@id}><%= @label %></.label>
      <.helper :if={@helper}><%= @helper %></.helper>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Form.normalize_value(@type, @value)}
        aria-describedby={@aria_describedby}
        class={[
          "block w-full rounded-lg px-3 py-2",
          "text-gray-900 focus:outline-none focus:ring-4 sm:text-sm sm:leading-6",
          @mt && "mt-2",
          @errors == [] && "border-gray-200 focus:ring-gray-700/5 focus:border-indigo-500",
          @errors != [] && "border-pink-500 focus:ring-pink-500/10 focus:border-pink-500"
        ]}
        {@rest}
      />

      <div id={@aria_describedby} role="alert">
        <.error :for={msg <- @errors}><%= msg %></.error>
      </div>
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
    <label for={@for} class="block text-sm font-semibold leading-6 text-gray-900">
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Renders a helper text.
  """
  slot :inner_block, required: true

  def helper(assigns) do
    ~H"""
    <span class="text-sm leading-6 text-gray-500"><%= render_slot(@inner_block) %></span>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="mt-3 flex gap-3 text-sm leading-6 text-pink-500">
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
      Gettext.dngettext(ZoonkWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(ZoonkWeb.Gettext, "errors", msg, opts)
    end
  end
end
