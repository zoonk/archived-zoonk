defmodule ZoonkWeb.Controller.Home do
  @moduledoc false
  use ZoonkWeb, :controller

  alias Zoonk.Content

  @spec index(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def index(conn, params) do
    %{current_user: user, school: school} = conn.assigns
    slug = Content.get_last_completed_course_slug(school, user)
    index(conn, params, slug)
  end

  defp index(conn, _params, nil), do: conn |> redirect(to: ~p"/courses") |> halt()
  defp index(conn, _params, slug), do: conn |> redirect(to: ~p"/c/#{slug}") |> halt()
end
