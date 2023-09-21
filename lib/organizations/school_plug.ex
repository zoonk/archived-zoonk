defmodule UneebeeWeb.Plugs.School do
  @moduledoc """
  School-related plugs.
  """
  use UneebeeWeb, :verified_routes

  import Plug.Conn

  alias Phoenix.Controller
  alias Uneebee.Organizations

  @doc """
  Checks if the school is already configured.

  If so, then we don't want to show the configuration page.
  """
  @spec check_school_setup(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def check_school_setup(%{request_path: "/schools/new"} = conn, opts),
    do: check_school_setup(conn, opts, Organizations.school_configured?())

  def check_school_setup(conn, _opts), do: conn

  # If the school is already configured, we don't want to show the configuration page.
  defp check_school_setup(_conn, _opts, true), do: raise(UneebeeWeb.PermissionError, code: :school_already_configured)
  defp check_school_setup(conn, _opts, false), do: conn

  @doc """
  Redirect to the setup page if the school isn't configured.
  """
  @spec setup_school(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def setup_school(%{request_path: "/"} = conn, opts), do: setup_school(conn, opts, Organizations.school_configured?())
  def setup_school(conn, _opts), do: conn

  defp setup_school(conn, _opts, true), do: conn
  defp setup_school(conn, _opts, false), do: conn |> Controller.redirect(to: ~p"/schools/new") |> halt()
end
