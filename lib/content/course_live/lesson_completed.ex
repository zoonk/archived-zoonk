defmodule ZoonkWeb.Live.LessonCompleted do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Content
  alias Zoonk.Content.UserLesson

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{lesson: lesson, current_user: user} = socket.assigns

    user_lesson = Content.get_user_lesson(user.id, lesson.id)

    if is_nil(user_lesson), do: raise(ZoonkWeb.PermissionError, code: :permission_denied)

    socket =
      socket
      |> assign(:page_title, lesson.name)
      |> assign(:user_lesson, user_lesson)

    {:ok, socket}
  end

  # for readonly steps, correct and total will be 0, so we want to display a 10 score
  defp get_score(%UserLesson{correct: 0, total: 0}), do: 10.0
  defp get_score(%UserLesson{correct: correct, total: total}), do: Float.round(correct / total * 10, 1)

  defp score_title(score) when score == 10.0, do: dgettext("courses", "Perfect!")
  defp score_title(score) when score >= 9.0, do: dgettext("courses", "Excellent!")
  defp score_title(score) when score >= 8.0, do: dgettext("courses", "Very good!")
  defp score_title(score) when score >= 7.0, do: dgettext("courses", "Good!")
  defp score_title(score) when score >= 6.0, do: dgettext("courses", "Not bad!")
  defp score_title(_score), do: dgettext("courses", "There's room for improvement")

  defp score_image(score) when score == 10.0, do: ~p"/images/lessons/perfect.svg"
  defp score_image(score) when score >= 7.0, do: ~p"/images/lessons/good.svg"
  defp score_image(_score), do: ~p"/images/lessons/improve.svg"

  defp win?(score), do: score >= 6.0

  defp badge_color(score) when score >= 8, do: :success
  defp badge_color(score) when score >= 6, do: :warning
  defp badge_color(_score), do: :alert
end
