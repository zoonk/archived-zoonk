defmodule Uneebee.Content.Lesson do
  @moduledoc """
  Lesson schema.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Uneebee.Content.UserLesson
  alias Uneebee.Content.UserSelection

  @type t :: %__MODULE__{}

  schema "lessons" do
    field :cover, :string
    field :description, :string
    field :name, :string
    field :order, :integer
    field :published?, :boolean, default: false

    belongs_to :course, Uneebee.Content.Course

    has_many :user_lessons, UserLesson
    has_many :user_selections, UserSelection

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(lesson, attrs) do
    lesson
    |> cast(attrs, [:cover, :course_id, :description, :name, :order, :published?])
    |> validate_required([:course_id, :description, :name, :order])
  end
end
