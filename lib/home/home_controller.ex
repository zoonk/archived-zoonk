defmodule UneebeeWeb.Controller.Home do
  @moduledoc false
  use UneebeeWeb, :controller

  alias Uneebee.Content

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, params) do
    slug = Content.get_last_completed_course_slug(conn.assigns.current_user)
    index(conn, params, slug)
  end

  defp index(conn, _params, nil), do: conn |> redirect(to: ~p"/courses") |> halt()
  defp index(conn, _params, slug), do: conn |> redirect(to: ~p"/c/#{slug}") |> halt()
end
