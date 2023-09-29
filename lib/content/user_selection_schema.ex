defmodule Uneebee.Content.UserSelection do
  @moduledoc """
  User selection schema.

  Keeps track of user selections when playing courses. For example: which steps they played and what options they've selected.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Uneebee.Accounts.User
  alias Uneebee.Content.Lesson
  alias Uneebee.Content.StepOption

  @type t :: %__MODULE__{}

  schema "user_selections" do
    belongs_to :user, User
    belongs_to :lesson, Lesson
    belongs_to :option, StepOption

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(user_selection, attrs \\ %{}) do
    user_selection
    |> cast(attrs, [:user_id, :option_id, :lesson_id])
    |> validate_required([:user_id, :option_id, :lesson_id])
  end
end
