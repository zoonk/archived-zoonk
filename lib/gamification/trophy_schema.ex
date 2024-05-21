defmodule Zoonk.Gamification.UserTrophy do
  @moduledoc """
  UserTrophy schema.

  When users complete courses or missions, they earn trophies.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Zoonk.Accounts.User
  alias Zoonk.Content.Course
  alias Zoonk.Gamification.TrophyUtils
  alias Zoonk.Gamification.UserMission

  @type t :: %__MODULE__{}

  schema "user_trophies" do
    field :reason, Ecto.Enum, values: TrophyUtils.trophy_keys()

    belongs_to :course, Course
    belongs_to :mission, UserMission
    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(user_trophy, attrs) do
    user_trophy
    |> cast(attrs, [:reason, :course_id, :mission_id, :user_id])
    |> validate_required([:reason, :user_id])
    |> maybe_require_mission_id()
    |> maybe_require_course_id()
    |> unique_constraint([:user_id, :course_id, :reason])
    |> unique_constraint([:user_id, :mission_id])
  end

  # Requires a mission_id when the `reason` is `:mission_completed`.
  defp maybe_require_mission_id(changeset), do: maybe_require_mission_id(changeset, get_change(changeset, :reason))
  defp maybe_require_mission_id(changeset, :mission_completed), do: validate_required(changeset, [:mission_id])
  defp maybe_require_mission_id(changeset, _reason), do: changeset

  # Requires a course_id when the `reason` is `:course_completed`.
  defp maybe_require_course_id(changeset), do: maybe_require_course_id(changeset, get_change(changeset, :reason))
  defp maybe_require_course_id(changeset, :course_completed), do: validate_required(changeset, [:course_id])
  defp maybe_require_course_id(changeset, _reason), do: changeset
end
