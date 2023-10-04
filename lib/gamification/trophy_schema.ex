defmodule Uneebee.Gamification.UserTrophy do
  @moduledoc """
  UserTrophy schema.

  When users complete courses or missions, they earn trophies.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Uneebee.Accounts.User
  alias Uneebee.Content.Course
  alias Uneebee.Gamification.TrophyUtils

  @type t :: %__MODULE__{}

  schema "user_trophies" do
    field :reason, Ecto.Enum, values: TrophyUtils.trophy_keys()

    belongs_to :course, Course
    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(user_trophy, attrs) do
    user_trophy
    |> cast(attrs, [:reason, :course_id, :user_id])
    |> validate_required([:reason, :user_id])
    |> unique_constraint([:user_id, :course_id, :reason])
  end
end
