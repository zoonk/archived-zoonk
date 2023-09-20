defmodule Uneebee.Organizations.School do
  @moduledoc """
  School schema.
  """
  use Ecto.Schema

  import Ecto.Changeset
  import UneebeeWeb.Gettext
  import UneebeeWeb.Shared.Validators

  alias Uneebee.Accounts.User

  @type t :: %__MODULE__{}

  schema "schools" do
    field :email, :string
    field :logo, :string
    field :name, :string
    field :public?, :boolean, default: false
    field :slug, :string

    belongs_to :created_by, User

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(school, attrs) do
    school
    |> cast(attrs, [:created_by_id, :email, :logo, :name, :public?, :slug])
    |> validate_required([:created_by_id, :email, :name, :public?, :slug])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: dgettext("errors", "must have the @ sign and no spaces"))
    |> validate_length(:email, max: 160)
    |> validate_format(:logo, ~r/^(\/|https:\/\/)/, message: dgettext("errors", "must start with / or https://"))
    |> validate_slug(:slug)
    |> validate_unique_slug()
  end

  defp validate_unique_slug(changeset) do
    changeset
    |> unsafe_validate_unique(:slug, Uneebee.Repo)
    |> unique_constraint(:slug)
  end
end
