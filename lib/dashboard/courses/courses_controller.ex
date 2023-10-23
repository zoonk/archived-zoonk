defmodule UneebeeWeb.Controller.Dashboard.Courses do
  @moduledoc false
  use UneebeeWeb, :controller

  alias Uneebee.Content

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, params) do
    %{current_user: user, school: school, user_role: role} = conn.assigns
    index(conn, params, Content.get_last_edited_course_slug(school, user, role))
  end

  defp index(conn, _params, nil), do: conn |> redirect(to: ~p"/dashboard/courses/new") |> halt()
  defp index(conn, _params, slug), do: conn |> redirect(to: ~p"/dashboard/c/#{slug}") |> halt()
end
