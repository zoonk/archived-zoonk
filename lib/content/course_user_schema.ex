defmodule Uneebee.Content.CourseUser do
  @moduledoc """
  Schema for the relationship between courses and users.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Uneebee.Accounts.User
  alias Uneebee.Content.Course

  @type t :: %__MODULE__{}

  schema "course_users" do
    field :role, Ecto.Enum, values: [:teacher, :student]

    field :approved?, :boolean
    field :approved_at, :utc_datetime_usec
    belongs_to :approved_by, User

    belongs_to :user, User
    belongs_to :course, Course

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(course_user, attrs \\ %{}) do
    course_user
    |> cast(attrs, [:approved?, :approved_at, :approved_by_id, :role, :course_id, :user_id])
    |> validate_required([:role, :course_id, :user_id])
    |> unique_constraint([:course_id, :user_id])
  end
end
