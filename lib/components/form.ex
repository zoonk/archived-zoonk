# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule UneebeeWeb.Components.Form do
  @moduledoc """
  Form components.
  """
  use Phoenix.Component

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"
  attr :class, :string, default: nil, doc: "the form class"
  attr :unstyled, :boolean, default: false, doc: "whether to remove the default styling to the form"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form
      :let={f}
      for={@for}
      as={@as}
      class={["space-y-4", not @unstyled && "bg-white rounded-xl shadow p-4", @class]}
      {@rest}
    >
      <%= render_slot(@inner_block, f) %>

      <div :for={action <- @actions} class="mt-2 flex items-center gap-4">
        <%= render_slot(action, f) %>
      </div>
    </.form>
    """
  end
end
