defmodule Zoonk.Gamification.UserMedal do
  @moduledoc """
  UserMedal schema.

  When users complete lessons, they earn medals. This aims to motivate them to
  complete more lessons and keep learning.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Zoonk.Accounts.User
  alias Zoonk.Content.Lesson
  alias Zoonk.Gamification.MedalUtils
  alias Zoonk.Gamification.UserMission

  @type t :: %__MODULE__{}

  schema "user_medals" do
    field :medal, Ecto.Enum, values: [:bronze, :silver, :gold]
    field :reason, Ecto.Enum, values: MedalUtils.medal_keys()

    belongs_to :lesson, Lesson
    belongs_to :mission, UserMission
    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(user_medal, attrs) do
    user_medal
    |> cast(attrs, [:medal, :reason, :lesson_id, :mission_id, :user_id])
    |> validate_required([:medal, :reason, :user_id])
    |> maybe_require_lesson_id()
    |> maybe_require_mission_id()
    |> unique_constraint([:user_id, :mission_id])
    |> unique_constraint([:user_id, :lesson_id, :reason])
  end

  # Requires a lesson_id when the `reason`includes the word `lesson`.
  defp maybe_require_lesson_id(changeset), do: maybe_require_lesson_id(changeset, lesson?(get_change(changeset, :reason)))
  defp maybe_require_lesson_id(changeset, true), do: validate_required(changeset, [:lesson_id])
  defp maybe_require_lesson_id(changeset, _reason), do: changeset
  defp lesson?(reason), do: reason |> to_string() |> String.contains?("lesson")

  # Requires a mission_id when the `reason` is `:mission_completed`.
  defp maybe_require_mission_id(changeset), do: maybe_require_mission_id(changeset, get_change(changeset, :reason))
  defp maybe_require_mission_id(changeset, :mission_completed), do: validate_required(changeset, [:mission_id])
  defp maybe_require_mission_id(changeset, _reason), do: changeset
end
