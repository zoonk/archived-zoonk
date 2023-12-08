# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule UneebeeWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use UneebeeWeb, :controller
      use UneebeeWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets audios fonts images favicon uploads robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Phoenix.Controller
      import Phoenix.LiveView.Router
      import Plug.Conn
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: UneebeeWeb.Layouts]

      import Plug.Conn
      import UneebeeWeb.Gettext

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView, layout: {UneebeeWeb.Layouts, :app}

      on_mount UneebeeWeb.Flash
      on_mount UneebeeWeb.Plugs.ActivePage

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      import UneebeeWeb.Flash, only: [put_flash!: 3]

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML

      # UI components
      import UneebeeWeb.Components.Avatar
      import UneebeeWeb.Components.AwardBadge
      import UneebeeWeb.Components.Badge
      import UneebeeWeb.Components.Button
      import UneebeeWeb.Components.Drawer
      import UneebeeWeb.Components.Flash
      import UneebeeWeb.Components.Form
      import UneebeeWeb.Components.Header
      import UneebeeWeb.Components.Icon
      import UneebeeWeb.Components.Input
      import UneebeeWeb.Components.Link
      import UneebeeWeb.Components.Menu
      import UneebeeWeb.Components.Modal
      import UneebeeWeb.Components.Progress
      import UneebeeWeb.Components.SearchBox
      import UneebeeWeb.Components.Utils

      # i18n
      import UneebeeWeb.Gettext

      alias Phoenix.LiveView.JS

      # Shortcut for generating JS commands

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: UneebeeWeb.Endpoint,
        router: UneebeeWeb.Router,
        statics: UneebeeWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
