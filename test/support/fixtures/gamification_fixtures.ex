defmodule Uneebee.Fixtures.Gamification do
  @moduledoc """
  This module defines test helpers for creating entities via the `Uneebee.Gamification` context.
  """
  import Uneebee.Fixtures.Accounts
  import Uneebee.Fixtures.Content

  alias Uneebee.Gamification
  alias Uneebee.Gamification.UserMedal

  @doc """
  Generates a user medal.
  """
  @spec user_medal_fixture(map()) :: UserMedal.t()
  def user_medal_fixture(attrs \\ %{}) do
    user = Map.get(attrs, :user, user_fixture())
    lesson = Map.get(attrs, :lesson, lesson_fixture())
    medal = Map.get(attrs, :medal, :gold)
    reason = Map.get(attrs, :reason, :perfect_lesson_first_try)

    attrs = %{user_id: user.id, lesson_id: lesson.id, medal: medal, reason: reason}

    {:ok, %UserMedal{} = user_medal} = Gamification.create_user_medal(attrs)
    user_medal
  end
end
