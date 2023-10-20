defmodule Uneebee.Content.CourseUtils do
  @moduledoc """
  Reusable configuration and utilities for courses.
  """

  import UneebeeWeb.Gettext

  alias Uneebee.Accounts.User
  alias Uneebee.Content.Lesson
  alias Uneebee.Content.UserLesson

  @spec max_length(atom()) :: non_neg_integer()
  def max_length(:option_feedback), do: 280
  def max_length(:option_title), do: 80
  def max_length(:step_content), do: 280

  @doc """
  Returns the list of supported levels for the course.
  """
  @spec levels() :: [{atom(), String.t()}]
  def levels do
    [
      beginner: dgettext("courses", "Beginner"),
      intermediate: dgettext("courses", "Intermediate"),
      advanced: dgettext("courses", "Advanced"),
      expert: dgettext("courses", "Expert")
    ]
  end

  @doc """
  Returns the list of level keys.
  """
  @spec level_keys() :: [atom()]
  def level_keys do
    Enum.map(levels(), &elem(&1, 0))
  end

  @doc """
  Level options for displaying on a `select` component where the label is the key and the key is the value.
  """
  @spec level_options() :: [{String.t(), atom()}]
  def level_options do
    Enum.map(levels(), fn {key, value} -> {value, Atom.to_string(key)} end)
  end

  @doc """
  Returns a label for a given level key.
  """
  @spec level_label(atom()) :: String.t()
  def level_label(level) do
    Keyword.get(levels(), level)
  end

  @doc """
  Calculate a course's progress based on how many lessons a user has completed.
  """
  @spec course_progress([Lesson.t()], User.t() | nil) :: integer()
  def course_progress(_lessons, nil), do: 0
  def course_progress([], _user), do: 0

  def course_progress(lessons, _user) do
    total = length(lessons)
    completed = completed_lessons_count(lessons)
    round(completed / total * 100)
  end

  # Calculate how many lessons are completed. A lesson is completed when `user_lessons` is an empty list.
  defp completed_lessons_count(lessons) do
    Enum.count(lessons, fn lesson -> lesson.user_lessons != [] end)
  end

  @doc """
  Calculate a course's score based on how many answers a user has gotten correct.
  """
  @spec course_score([Lesson.t()]) :: float() | nil
  def course_score(lessons) do
    %{correct: correct, total: total} = Enum.reduce(lessons, %{correct: 0, total: 0}, &score_acc/2)
    score(correct, total)
  end

  defp score_acc(%{user_lessons: [%{correct: correct, total: total}]}, acc) do
    %{acc | correct: acc.correct + correct, total: acc.total + total}
  end

  defp score_acc(_lesson, acc), do: acc

  @doc """
  Returns the color for a given score.
  """
  @spec score_color(float() | nil) :: atom()
  def score_color(nil), do: :success_light
  def score_color(score) when score >= 8, do: :success_light
  def score_color(score) when score >= 6, do: :warning_light
  def score_color(_score), do: :alert_light

  @doc """
  Checks if a lesson is completed.
  """
  @spec lesson_completed?(User.t(), [UserLesson.t()]) :: boolean()
  def lesson_completed?(user, user_lessons), do: user |> get_user_lesson(user_lessons) |> lesson_completed?()
  defp lesson_completed?(nil), do: false
  defp lesson_completed?(_ul), do: true

  @doc """
  Returns the score for a given lesson.
  """
  @spec lesson_score(User.t() | nil, [UserLesson.t()]) :: float() | nil
  def lesson_score(user, user_lessons), do: user |> get_user_lesson(user_lessons) |> lesson_score()
  defp lesson_score(nil), do: nil
  defp lesson_score(%UserLesson{correct: correct, total: total}), do: score(correct, total)

  defp get_user_lesson(nil, _ul), do: nil
  defp get_user_lesson(_user, []), do: nil
  defp get_user_lesson(_user, user_lessons), do: Enum.at(user_lessons, 0)

  defp score(_correct, 0), do: nil
  defp score(correct, total), do: Float.round(correct / total * 10, 1)
end
