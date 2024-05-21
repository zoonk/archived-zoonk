defmodule Zoonk.Organizations.SchoolUser do
  @moduledoc """
  Schema for the relationship between schools and users.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias Zoonk.Accounts.User
  alias Zoonk.Organizations.School

  @type t :: %__MODULE__{}

  schema "school_users" do
    field :role, Ecto.Enum, values: [:manager, :teacher, :student], default: :student

    field :analytics?, :boolean, default: true
    field :approved?, :boolean, default: false
    field :approved_at, :utc_datetime_usec
    belongs_to :approved_by, User

    belongs_to :school, School
    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(school_user, attrs \\ %{}) do
    school_user
    |> cast(attrs, [:analytics?, :approved?, :approved_at, :approved_by_id, :role, :school_id, :user_id])
    |> validate_required([:analytics?, :role, :school_id, :user_id])
    |> unique_constraint([:school_id, :user_id])
  end
end
