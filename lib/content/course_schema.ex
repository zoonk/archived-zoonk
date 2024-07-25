defmodule Zoonk.Content.Course do
  @moduledoc """
  Course schema.
  """
  use Ecto.Schema

  import Ecto.Changeset
  import Zoonk.Shared.Validators

  alias Zoonk.Content.CourseUser
  alias Zoonk.Content.CourseUtils
  alias Zoonk.Content.Lesson
  alias Zoonk.Organizations.School
  alias ZoonkWeb.Plugs.Translate

  @type t :: %__MODULE__{}

  schema "courses" do
    field :cover, :string
    field :description, :string
    field :language, Ecto.Enum, values: Translate.supported_locales()
    field :level, Ecto.Enum, values: CourseUtils.level_keys(), default: :beginner
    field :name, :string
    field :public?, :boolean, default: true
    field :published?, :boolean, default: false
    field :slug, :string

    belongs_to :school, School

    has_many :lessons, Lesson
    has_many :users, CourseUser

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(course, attrs) do
    course
    |> cast(attrs, [:cover, :description, :language, :level, :name, :public?, :published?, :school_id, :slug])
    |> validate_required([:description, :language, :name, :school_id, :slug])
    |> validate_slug(:slug)
    |> unsafe_validate_unique([:slug, :school_id], Zoonk.Repo)
    |> unique_constraint([:slug, :school_id])
  end
end
