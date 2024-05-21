defmodule Zoonk.Content.UserLesson do
  @moduledoc """
  User lesson schema.

  Keeps track of all lessons completed by a user.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Zoonk.Accounts.User
  alias Zoonk.Content.Lesson

  @type t :: %__MODULE__{}

  schema "user_lessons" do
    field :attempts, :integer, default: 0
    field :correct, :integer, default: 0
    field :total, :integer, default: 0
    field :duration, :integer, default: 0

    belongs_to :user, User
    belongs_to :lesson, Lesson

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(user_lesson, attrs \\ %{}) do
    user_lesson
    |> cast(attrs, [:user_id, :lesson_id, :attempts, :correct, :total, :duration])
    |> validate_required([:user_id, :lesson_id, :attempts, :correct, :total, :duration])
  end
end
