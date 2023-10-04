defmodule Uneebee.Gamification.UserMedal do
  @moduledoc """
  UserMedal schema.

  When users complete lessons, they earn medals. This aims to motivate them to
  complete more lessons and keep learning.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Uneebee.Accounts.User
  alias Uneebee.Content.Lesson
  alias Uneebee.Gamification.MedalUtils

  @type t :: %__MODULE__{}

  schema "user_medals" do
    field :medal, Ecto.Enum, values: [:bronze, :silver, :gold]
    field :reason, Ecto.Enum, values: MedalUtils.medal_keys()

    belongs_to :lesson, Lesson
    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(user_medal, attrs) do
    user_medal
    |> cast(attrs, [:medal, :reason, :lesson_id, :user_id])
    |> validate_required([:medal, :reason, :user_id])
  end
end
