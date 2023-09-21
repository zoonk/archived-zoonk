defmodule UneebeeWeb.Plugs.School do
  @moduledoc """
  School-related plugs.
  """
  use UneebeeWeb, :verified_routes

  alias Uneebee.Organizations

  @doc """
  Handles the host school configuration process.
  """
  @spec host_school_setup(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def host_school_setup(%{request_path: "/schools/new"} = conn, _opts) do
    handle_new_school_page(conn, Organizations.school_configured?())
  end

  def host_school_setup(conn, _opts), do: conn

  defp handle_new_school_page(_conn, true), do: raise(UneebeeWeb.PermissionError, code: :school_already_configured)
  defp handle_new_school_page(conn, false), do: conn
end
