defmodule Uneebee.Organizations.School do
  @moduledoc """
  School schema.
  """
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query
  import UneebeeWeb.Gettext
  import UneebeeWeb.Shared.Validators

  alias Uneebee.Accounts.User
  alias Uneebee.Organizations.School
  alias Uneebee.Organizations.SchoolUser
  alias Uneebee.Repo

  @type t :: %__MODULE__{}

  schema "schools" do
    field :custom_domain, :string
    field :email, :string
    field :logo, :string
    field :name, :string
    field :privacy_policy, :string
    field :public?, :boolean, default: true
    field :require_confirmation?, :boolean, default: false
    field :slug, :string
    field :terms_of_use, :string

    belongs_to :created_by, User
    belongs_to :school, School

    has_many :users, SchoolUser

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(school, attrs) do
    school
    |> cast(attrs, [:created_by_id, :custom_domain, :email, :logo, :name, :privacy_policy, :public?, :require_confirmation?, :terms_of_use, :school_id, :slug])
    |> validate_required([:created_by_id, :email, :name, :public?, :slug])
    |> unique_constraint(:custom_domain)
    |> validate_email(:email)
    |> validate_format(:logo, ~r/^(\/|https:\/\/)/, message: dgettext("errors", "must start with / or https://"))
    |> validate_format(:privacy_policy, ~r/^https:\/\//, message: dgettext("errors", "must start with https://"))
    |> validate_format(:terms_of_use, ~r/^https:\/\//, message: dgettext("errors", "must start with https://"))
    |> validate_slug(:slug)
    |> validate_unique_slug()
    |> validate_custom_domain()
  end

  defp validate_unique_slug(changeset) do
    changeset
    |> unsafe_validate_unique(:slug, Uneebee.Repo)
    |> unique_constraint(:slug)
  end

  # Don't allow to add a subdomain as `custom_domain` if that domain already exists.
  defp validate_custom_domain(changeset) do
    custom_domain = get_change(changeset, :custom_domain)

    if is_binary(custom_domain) && domain_exists?(changeset) do
      add_error(changeset, :custom_domain, dgettext("errors", "has already been taken"))
    else
      changeset
    end
  end

  # In some cases the domain (`host`) could have multiple paths creating conflicts with existing domains.
  # For example: `science.app.uneebee.com`, `app.uneebee.com` all have the same `uneebee.com` domain.
  # This is a problem because we use the school's username as a subdomain.
  # So, if a school sets `science.app.uneebee.com` as their custom domain, this would cause a conflict with schools using the `science` username.
  # Hence, we drop the first part of the domain to see if the last parts match any custom domains other schools have.
  defp extract_domain(changeset) do
    custom_domain = get_change(changeset, :custom_domain)
    domain_parts = String.split(custom_domain, ".")

    domain_parts
    # Only drop the first part for domains that have more than one part.
    # Otherwise, we could drop the `uneebee` part from `uneebee.com`, for example.
    |> Enum.drop(if(length(domain_parts) > 2, do: 1, else: 0))
    |> Enum.join(".")
  end

  defp domain_exists?(changeset) do
    domain = extract_domain(changeset)

    School
    |> where([school], fragment("? ILIKE '%' || ?", school.custom_domain, ^domain))
    |> Repo.exists?()
  end
end
