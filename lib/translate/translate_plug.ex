defmodule UneebeeWeb.Plugs.Translate do
  @moduledoc """
  Reusable functions for setting up multiple languages and translations.
  """
  import Plug.Conn

  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

  @supported_languages [en: "English", pt: "Português", zh_TW: "繁體中文"]
  @default_locale "en"

  @doc """
  List all keys for supported languages.
  """
  @spec supported_locales() :: [atom()]
  def supported_locales do
    Enum.map(@supported_languages, fn {key, _value} -> key end)
  end

  @doc """
  Language options for displaying on a `select` component where the label is the key and the key is the value.
  """
  @spec language_options() :: [{String.t(), atom()}]
  def language_options do
    Enum.map(@supported_languages, fn {key, value} -> {value, Atom.to_string(key)} end)
  end

  @doc """
  Get user's defined locale and set it to `Gettext`. When the user hasn't defined a locale it,
  we use the one defined at the current session.
  """
  @spec on_mount(atom(), LiveView.unsigned_params(), map(), Socket.t()) :: {:cont, Socket.t()}
  def on_mount(:set_locale_from_session, _params, session, socket) do
    user = socket.assigns.current_user
    locale = if user, do: Atom.to_string(user.language), else: Map.get(session, "locale")

    Gettext.put_locale(UneebeeWeb.Gettext, locale)

    {:cont, socket}
  end

  @doc """
  Plug for adding a locale to the current session.

    * `current_user`: Use the locale set by the user in their settings.
    * `unauthenticated`: Use the browser's locale.
  """
  @spec set_session_locale(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def set_session_locale(%{assigns: %{current_user: %{language: locale}}} = conn, _opts) do
    set_locale(conn, Atom.to_string(locale))
  end

  def set_session_locale(conn, _opts) do
    set_locale(conn, get_browser_locale(conn))
  end

  # Add the locale to the session and to `Gettext`
  @spec set_locale(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  defp set_locale(conn, locale) do
    Gettext.put_locale(UneebeeWeb.Gettext, locale)
    put_session(conn, :locale, locale)
  end

  @doc """
  Get the browser's locale.

  This is a naive implementation that only takes the first locale from the `accept-language` header.
  If it's not supported by this application, it will return the `@default_locale`.
  """
  @spec get_browser_locale(Plug.Conn.t()) :: String.t()
  def get_browser_locale(conn) do
    locale = extract_locale(get_req_header(conn, "accept-language"))

    # Converted supported locales to string
    supported = Enum.map(supported_locales(), fn locale -> Atom.to_string(locale) end)

    if Enum.member?(supported, locale), do: locale, else: @default_locale
  end

  # Parse the `accept-language` header and extract the first locale there.
  @spec extract_locale([String.t()]) :: String.t()
  defp extract_locale([accept_language | _]) do
    accept_language |> String.split("-") |> List.first()
  end

  defp extract_locale([]), do: @default_locale
end
