defmodule Uneebee.Fixtures.Gamification do
  @moduledoc """
  This module defines test helpers for creating entities via the `Uneebee.Gamification` context.
  """
  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Content

  alias Uneebee.Gamification
  alias Uneebee.Gamification.UserMedal
  alias Uneebee.Gamification.UserMission
  alias Uneebee.Gamification.UserTrophy
  alias Uneebee.Repo

  @doc """
  Generates a user medal.
  """
  @spec user_medal_fixture(map()) :: UserMedal.t()
  def user_medal_fixture(attrs \\ %{}) do
    user = Map.get(attrs, :user, user_fixture())
    lesson = Map.get(attrs, :lesson, lesson_fixture())
    medal = Map.get(attrs, :medal, :gold)
    mission = Map.get(attrs, :mission, user_mission_fixture())
    reason = Map.get(attrs, :reason, :perfect_lesson_first_try)

    attrs = %{user_id: user.id, lesson_id: lesson_id(reason, lesson), medal: medal, mission_id: mission_id(reason, mission), reason: reason}

    {:ok, %UserMedal{} = user_medal} = Gamification.create_user_medal(attrs)
    user_medal
  end

  @doc """
  Generates a user trophy.
  """
  @spec user_trophy_fixture(map()) :: UserTrophy.t()
  def user_trophy_fixture(attrs \\ %{}) do
    user = Map.get(attrs, :user, user_fixture())
    course = Map.get(attrs, :course, course_fixture())
    mission = Map.get(attrs, :mission, user_mission_fixture())
    reason = Map.get(attrs, :reason, :course_completed)
    preload = Map.get(attrs, :preload, [])

    attrs = %{user_id: user.id, course_id: course_id(reason, course), mission_id: mission_id(reason, mission), reason: reason}

    {:ok, %UserTrophy{} = user_trophy} = Gamification.create_user_trophy(attrs)
    Repo.preload(user_trophy, preload)
  end

  defp course_id(:course_completed, course), do: course.id
  defp course_id(_reason, _course), do: nil

  defp mission_id(:mission_completed, mission), do: mission.id
  defp mission_id(_reason, _mission), do: nil

  defp lesson_id(reason, lesson), do: if(lesson?(reason), do: lesson.id)

  defp lesson?(reason), do: reason |> to_string() |> String.contains?("lesson")

  @doc """
  Generates a user mission.
  """
  @spec user_mission_fixture(map()) :: UserMission.t()
  def user_mission_fixture(attrs \\ %{}) do
    user = Map.get(attrs, :user, user_fixture())
    reason = Map.get(attrs, :reason, :profile_name)

    attrs = %{user_id: user.id, reason: reason}

    {:ok, %UserMission{} = user_mission} = Gamification.create_user_mission(attrs)
    user_mission
  end
end
