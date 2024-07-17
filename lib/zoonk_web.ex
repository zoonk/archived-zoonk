# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule ZoonkWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use ZoonkWeb, :controller
      use ZoonkWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets audios fonts images favicon robots.txt)

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
        layouts: [html: ZoonkWeb.Layouts]

      import Plug.Conn
      import ZoonkWeb.Gettext

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView, layout: {ZoonkWeb.Layouts, :app}

      on_mount ZoonkWeb.Flash
      on_mount ZoonkWeb.Plugs.ActivePage
      on_mount Sentry.LiveViewHook

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      import ZoonkWeb.Flash, only: [put_flash!: 3]

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
      import ZoonkWeb.Components.Avatar
      import ZoonkWeb.Components.Badge
      import ZoonkWeb.Components.Button
      import ZoonkWeb.Components.Drawer
      import ZoonkWeb.Components.Flash
      import ZoonkWeb.Components.Form
      import ZoonkWeb.Components.Header
      import ZoonkWeb.Components.Icon
      import ZoonkWeb.Components.Input
      import ZoonkWeb.Components.Link
      import ZoonkWeb.Components.Menu
      import ZoonkWeb.Components.Modal
      import ZoonkWeb.Components.Progress
      import ZoonkWeb.Components.SearchBox
      import ZoonkWeb.Components.Utils
      import ZoonkWeb.Components.YouTube

      # i18n
      import ZoonkWeb.Gettext
      import ZoonkWeb.Shared.Utilities

      alias Phoenix.LiveView.JS

      # Shortcut for generating JS commands

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: ZoonkWeb.Endpoint,
        router: ZoonkWeb.Router,
        statics: ZoonkWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
