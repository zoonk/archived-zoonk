defmodule ZoonkWeb.Controller.Dashboard.Courses do
  @moduledoc false
  use ZoonkWeb, :controller

  alias Zoonk.Content

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, params) do
    %{current_user: user, school: school, user_role: role} = conn.assigns
    index(conn, params, Content.get_last_edited_course(school, user, role))
  end

  defp index(conn, _params, nil), do: conn |> redirect(to: ~p"/dashboard/courses/new") |> halt()
  defp index(conn, _params, course), do: conn |> redirect(to: ~p"/dashboard/c/#{course.slug}") |> halt()
end
