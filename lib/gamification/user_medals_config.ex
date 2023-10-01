defmodule Uneebee.Gamification.UserMedal.Config do
  @moduledoc """
  UserMedal configuration.
  """
  import UneebeeWeb.Gettext

  alias Uneebee.Gamification.Medal

  @doc """
  Supported reasons for receiving a medal.

  Returns a list of %Medal{} for the supported reasons for earning a medal.
  """
  @spec medals() :: list(Medal.t())
  def medals do
    [
      %Medal{
        key: :perfect_lesson_first_try,
        medal: :gold,
        label: dgettext("gamification", "Perfect lesson"),
        description: dgettext("gamification", "You completed a lesson without any errors on your first try.")
      },
      %Medal{
        key: :perfect_lesson_practiced,
        medal: :silver,
        label: dgettext("gamification", "Perfect lesson"),
        description: dgettext("gamification", "You completed a lesson without any errors after practicing it.")
      },
      %Medal{
        key: :lesson_completed_with_errors,
        medal: :bronze,
        label: dgettext("gamification", "Lesson completed"),
        description: dgettext("gamification", "You completed a lesson with some errors on your first try.")
      },
      %Medal{
        key: :lesson_practiced,
        medal: :bronze,
        label: dgettext("gamification", "Lesson practiced"),
        description: dgettext("gamification", "You practiced a lesson you had completed before.")
      }
    ]
  end

  @doc """
  Medal keys.

  Returns a list of atom keys for the supported medals.
  """
  @spec medal_keys() :: list(atom())
  def medal_keys do
    Enum.map(medals(), & &1.key)
  end

  @doc """
  Get a medal type by key.
  """
  @spec medal_type(atom()) :: atom()
  def medal_type(key) do
    medals() |> Enum.find(fn medal -> medal.key == key end) |> Map.get(:medal)
  end
end
