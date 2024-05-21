defmodule ZoonkWeb.Plugs.CspNonce do
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
end
