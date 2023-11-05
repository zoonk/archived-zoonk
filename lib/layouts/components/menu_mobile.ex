# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule UneebeeWeb.Components.Layouts.MenuMobile do
  @moduledoc false
  use UneebeeWeb, :html

  import UneebeeWeb.Layouts.MenuUtils

  def menu_mobile(assigns) do
    ~H"""
    <.drawer id="mobile-menu">
      <div class="flex grow flex-col gap-y-5 overflow-y-auto bg-white px-6 pb-4">
        <div class="flex h-16 shrink-0 items-center">
          <img class="h-8 w-auto" src={school_logo(@school)} alt={school_name(@school)} />
        </div>

        <%= render_slot(@inner_block) %>
      </div>
    </.drawer>
    """
  end
end
