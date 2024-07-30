defmodule Zoonk.Content.UserSelection do
  @moduledoc """
  User selection schema.

  Keeps track of user selections when playing courses. For example: which steps they played and what options they've selected.
  """
  use Ecto.Schema

  import Ecto.Changeset
  import ZoonkWeb.Gettext

  alias Zoonk.Accounts.User
  alias Zoonk.Content.Lesson
  alias Zoonk.Content.LessonStep
  alias Zoonk.Content.StepOption

  @type t :: %__MODULE__{}

  schema "user_selections" do
    field :duration, :integer
    field :answer, {:array, :string}
    field :correct, :integer
    field :total, :integer

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
    |> cast(attrs, [:answer, :correct, :total, :duration, :user_id, :option_id, :lesson_id, :step_id])
    |> validate_required([:duration, :correct, :total, :user_id, :lesson_id, :step_id])
    |> validate_correct_total()
  end

  defp validate_correct_total(changeset) do
    correct = get_field(changeset, :correct)
    total = get_field(changeset, :total)
    validate_correct_total(changeset, correct, total)
  end

  defp validate_correct_total(changeset, correct, total) when correct > total do
    add_error(changeset, :correct, dgettext("errors", "cannot be larger than total"))
  end

  defp validate_correct_total(changeset, _correct, _total), do: changeset
end
