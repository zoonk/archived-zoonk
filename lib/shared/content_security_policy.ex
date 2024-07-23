defmodule ZoonkWeb.Plugs.ContentSecurityPolicy do
  @moduledoc """
  Set a CSP nonce for the current request.
  """

  @spec init(Keyword.t()) :: Keyword.t()
  def init(options), do: options

  @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def call(conn, opts) do
    nonce = Keyword.get(opts, :nonce)
    Plug.Conn.assign(conn, :csp_nonce, nonce)
  end

  @doc """
  Get allowed connect-src domains.

  ## Examples

      iex> ZoonkWeb.Plugs.CspNonce.get_connect_src()
      "https://fly.storage.tigris.dev"
  """
  @spec get_connect_src() :: String.t()
  def get_connect_src, do: Application.get_env(:zoonk, :csp)[:connect_src]
end
