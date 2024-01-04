defmodule Uneebee.Content.StepAnswer do
  @moduledoc """
  StepAnswer schema.

  Some steps can have open-ended answers instead of options. When users play that step, they will be able to write their answer.
  This schema is used to store their answers.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Uneebee.Accounts.User
  alias Uneebee.Content.LessonStep

  @type t :: %__MODULE__{}

  schema "step_answers" do
    belongs_to :lesson_step, LessonStep
    belongs_to :user, User

    field :answer, :string

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(step_answer, attrs) do
    step_answer
    |> cast(attrs, [:lesson_step_id, :user_id, :answer])
    |> validate_required([:lesson_step_id, :user_id, :answer])
  end
end
