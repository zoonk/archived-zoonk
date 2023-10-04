defmodule Uneebee.Gamification.MissionUtils do
  @moduledoc """
  Utility functions for missions.
  """
  import UneebeeWeb.Gettext

  alias Uneebee.Gamification.Mission

  @doc """
  Returns a list of supported missions.
  """
  @spec supported_missions() :: [Mission.t()]
  # credo:disable-for-next-line Credo.Check.Refactor.ABCSize
  def supported_missions do
    [
      %Mission{
        key: :profile_name,
        prize: :trophy,
        label: dgettext("gamification", "Profile name"),
        description: dgettext("gamification", "Add your name to your profile."),
        success_message: dgettext("gamification", "You added your name to your profile.")
      },
      %Mission{
        key: :lesson_first,
        prize: :trophy,
        label: dgettext("gamification", "First lesson"),
        description: dgettext("gamification", "Complete your first lesson."),
        success_message: dgettext("gamification", "You completed your first lesson.")
      },
      %Mission{
        key: :lesson_without_error,
        prize: :trophy,
        label: dgettext("gamification", "Perfect lesson"),
        description: dgettext("gamification", "Complete a lesson without errors."),
        success_message: dgettext("gamification", "You completed a lesson without errors.")
      },
      %Mission{
        key: :lesson_5,
        prize: :bronze,
        label: dgettext("gamification", "5 lessons"),
        description: dgettext("gamification", "Complete 5 lessons."),
        success_message: dgettext("gamification", "You completed 5 lessons.")
      },
      %Mission{
        key: :lesson_10,
        prize: :bronze,
        label: dgettext("gamification", "10 lessons"),
        description: dgettext("gamification", "Complete 10 lessons."),
        success_message: dgettext("gamification", "You completed 10 lessons.")
      },
      %Mission{
        key: :course_first,
        prize: :trophy,
        label: dgettext("gamification", "First course"),
        description: dgettext("gamification", "Complete your first course."),
        success_message: dgettext("gamification", "You completed your first course.")
      },
      %Mission{
        key: :course_without_error,
        prize: :trophy,
        label: dgettext("gamification", "Perfect course"),
        description: dgettext("gamification", "Complete a course without errors."),
        success_message: dgettext("gamification", "You completed a course without errors.")
      },
      %Mission{
        key: :course_2,
        prize: :trophy,
        label: dgettext("gamification", "Second course"),
        description: dgettext("gamification", "Complete 2 courses."),
        success_message: dgettext("gamification", "You completed 2 courses.")
      },
      %Mission{
        key: :lesson_50,
        prize: :silver,
        label: dgettext("gamification", "50 lessons"),
        description: dgettext("gamification", "Complete 50 lessons."),
        success_message: dgettext("gamification", "You completed 50 lessons.")
      },
      %Mission{
        key: :lesson_100,
        prize: :gold,
        label: dgettext("gamification", "100 lessons"),
        description: dgettext("gamification", "Complete 100 lessons."),
        success_message: dgettext("gamification", "You completed 100 lessons.")
      },
      %Mission{
        key: :lesson_500,
        prize: :gold,
        label: dgettext("gamification", "500 lessons"),
        description: dgettext("gamification", "Complete 500 lessons."),
        success_message: dgettext("gamification", "You completed 500 lessons.")
      },
      %Mission{
        key: :lesson_1000,
        prize: :trophy,
        label: dgettext("gamification", "1000 lessons"),
        description: dgettext("gamification", "Complete 1000 lessons."),
        success_message: dgettext("gamification", "You completed 1000 lessons.")
      },
      %Mission{
        key: :lesson_without_error_10,
        prize: :bronze,
        label: dgettext("gamification", "10 perfect lessons"),
        description: dgettext("gamification", "Complete 10 lessons without errors.")
      },
      %Mission{
        key: :lesson_without_error_50,
        prize: :silver,
        label: dgettext("gamification", "50 perfect lessons"),
        description: dgettext("gamification", "Complete 50 lessons without errors.")
      },
      %Mission{
        key: :lesson_without_error_100,
        prize: :gold,
        label: dgettext("gamification", "100 perfect lessons"),
        description: dgettext("gamification", "Complete 100 lessons without errors.")
      },
      %Mission{
        key: :lesson_without_error_500,
        prize: :trophy,
        label: dgettext("gamification", "500 perfect lessons"),
        description: dgettext("gamification", "Complete 500 lessons without errors.")
      },
      %Mission{
        key: :course_5,
        prize: :trophy,
        label: dgettext("gamification", "5 courses"),
        description: dgettext("gamification", "Complete 5 courses."),
        success_message: dgettext("gamification", "You completed 5 courses.")
      },
      %Mission{
        key: :course_10,
        prize: :trophy,
        label: dgettext("gamification", "10 courses"),
        description: dgettext("gamification", "Complete 10 courses."),
        success_message: dgettext("gamification", "You completed 10 courses.")
      }
    ]
  end

  @doc """
  Returns a list of supported mission keys.
  """
  @spec mission_keys() :: [atom()]
  def mission_keys do
    Enum.map(supported_missions(), & &1.key)
  end

  @doc """
  Get a mission by its key.
  """
  @spec get_mission(atom()) :: Mission.t()
  def get_mission(key) do
    Enum.find(supported_missions(), fn mission -> mission.key == key end)
  end
end
