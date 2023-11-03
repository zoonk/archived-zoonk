# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule UneebeeWeb.Components.Layouts.MenuDesktop do
  @moduledoc false
  use UneebeeWeb, :html

  import UneebeeWeb.Layouts.MenuUtils

  def menu_desktop(assigns) do
    ~H"""
    <div class="hidden lg:fixed lg:inset-y-0 lg:z-50 lg:flex lg:w-72 lg:flex-col">
      <div class="flex grow flex-col gap-y-5 overflow-y-auto border-r border-gray-200 bg-white px-6 pb-4">
        <div class="flex h-16 shrink-0 items-center">
          <img class="h-8 w-auto" src={school_logo(@school)} alt={school_name(@school)} />
        </div>

        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end
