defmodule ZoonkWeb.Live.LessonCompleted do
  @moduledoc false
  use ZoonkWeb, :live_view

  alias Zoonk.Content
  alias Zoonk.Content.UserLesson
  alias Zoonk.Gamification
  alias Zoonk.Gamification.MedalUtils
  alias Zoonk.Gamification.TrophyUtils
  alias Zoonk.Gamification.UserTrophy

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    %{lesson: lesson, current_user: user} = socket.assigns

    user_lesson = Content.get_user_lesson(user.id, lesson.id)

    if is_nil(user_lesson), do: raise(ZoonkWeb.PermissionError, code: :permission_denied)

    first_lesson_today? = Gamification.first_lesson_today?(user.id)
    learning_days = Gamification.learning_days_count(user.id)
    medal = get_medal(user_lesson)
    course_completed_trophy = Gamification.get_course_completed_trophy(user.id, lesson.course_id)

    socket =
      socket
      |> assign(:page_title, lesson.name)
      |> assign(:user_lesson, user_lesson)
      |> assign(:first_lesson_today?, first_lesson_today?)
      |> assign(:learning_days, learning_days)
      |> assign(:medal, medal)
      |> assign(:course_completed_trophy, course_completed_trophy)
      |> assign(:award_count, award_count(first_lesson_today?, medal, course_completed_trophy))

    {:ok, socket}
  end

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

  defp get_medal(%UserLesson{attempts: 1, correct: correct, total: total}) when correct == total, do: MedalUtils.medal(:perfect_lesson_first_try)
  defp get_medal(%UserLesson{attempts: 1}), do: MedalUtils.medal(:lesson_completed_with_errors)
  defp get_medal(%UserLesson{correct: correct, total: total}) when correct == total, do: MedalUtils.medal(:perfect_lesson_practiced)
  defp get_medal(_user_lesson), do: nil

  defp completed_course_recently?(nil), do: false

  defp completed_course_recently?(%UserTrophy{} = user_trophy) do
    DateTime.utc_now() |> DateTime.diff(user_trophy.updated_at, :minute) |> Kernel.<(3)
  end

  defp trophy(user_trophy), do: TrophyUtils.trophy(user_trophy.reason)

  defp badge_color(score) when score >= 8, do: :success
  defp badge_color(score) when score >= 6, do: :warning
  defp badge_color(_score), do: :alert

  defp award_count(first_lesson?, medal, user_trophy) do
    learning_day = if first_lesson?, do: 1, else: 0
    medal = if is_nil(medal), do: 0, else: 1
    trophy = if completed_course_recently?(user_trophy), do: 1, else: 0

    learning_day + medal + trophy
  end
end
