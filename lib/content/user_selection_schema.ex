defmodule Uneebee.Content.UserSelection do
  @moduledoc """
  User selection schema.

  Keeps track of user selections when playing courses. For example: which steps they played and what options they've selected.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Uneebee.Accounts.User
  alias Uneebee.Content.Lesson
  alias Uneebee.Content.LessonStep
  alias Uneebee.Content.StepOption

  @type t :: %__MODULE__{}

  schema "user_selections" do
    field :duration, :integer
    field :answer, :string

    belongs_to :user, User
    belongs_to :lesson, Lesson
    belongs_to :step, LessonStep
    belongs_to :option, StepOption

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(user_selection, attrs \\ %{}) do
    user_selection
    |> cast(attrs, [:answer, :duration, :user_id, :option_id, :lesson_id, :step_id])
    |> validate_required([:duration, :user_id, :lesson_id, :step_id])
  end
end
