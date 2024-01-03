defmodule UneebeeWeb.Controller.LessonStep do
  @moduledoc false
  use UneebeeWeb, :controller

  alias Uneebee.Content

  @spec add_suggested_course(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def add_suggested_course(conn, %{"course_slug" => course_slug, "lesson_id" => lesson_id, "step_order" => order, "course_id" => course_id}) do
    step = Content.get_lesson_step_by_order(lesson_id, order)

    case Content.add_step_suggested_course(%{lesson_step_id: step.id, course_id: course_id}) do
      {:ok, _suggested_course} ->
        conn
        |> put_flash(:info, dgettext("orgs", "Suggested course added successfully."))
        |> redirect(to: step_link(course_slug, lesson_id, order))

      {:error, _reason} ->
        conn
        |> put_flash(:error, dgettext("orgs", "Suggested course could not be added."))
        |> redirect(to: step_link(course_slug, lesson_id, order))
    end
  end

  defp step_link(course_slug, lesson_id, order), do: ~p"/dashboard/c/#{course_slug}/l/#{lesson_id}/s/#{order}"
end
