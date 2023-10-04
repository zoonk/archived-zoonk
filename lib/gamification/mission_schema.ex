defmodule Uneebee.Gamification.UserMission do
  @moduledoc """
  UserMission schema.

  When users complete missions, they earn prizes. This aims to help users to better
  understand the platform + motivate them to complete more lessons and keep learning.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Uneebee.Accounts.User
  alias Uneebee.Gamification.MissionUtils

  @type t :: %__MODULE__{}

  schema "user_missions" do
    field :reason, Ecto.Enum, values: MissionUtils.mission_keys()

    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(user_mission, attrs) do
    user_mission
    |> cast(attrs, [:reason, :user_id])
    |> validate_required([:reason, :user_id])
    |> unique_constraint([:reason, :user_id])
  end
end
