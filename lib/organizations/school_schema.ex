defmodule Zoonk.Organizations.School do
  @moduledoc """
  School schema.
  """
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query
  import ZoonkWeb.Gettext
  import ZoonkWeb.Shared.Validators

  alias Zoonk.Accounts.User
  alias Zoonk.Organizations.School
  alias Zoonk.Organizations.SchoolUser
  alias Zoonk.Organizations.SchoolUtils
  alias Zoonk.Repo

  @type t :: %__MODULE__{}

  schema "schools" do
    field :allow_guests?, :boolean, default: false
    field :currency, :string
    field :custom_domain, :string
    field :email, :string
    field :kind, Ecto.Enum, values: [:marketplace, :saas, :white_label], default: :white_label
    field :icon, :string
    field :logo, :string
    field :name, :string
    field :privacy_policy, :string
    field :public?, :boolean, default: false
    field :require_confirmation?, :boolean, default: false
    field :slug, :string
    field :terms_of_use, :string

    belongs_to :created_by, User
    belongs_to :school, School

    has_many :users, SchoolUser

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  @spec create_changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def create_changeset(school, attrs) do
    school
    |> cast(attrs, [:kind | shared_cast_fields()])
    |> default_changeset()
  end

  @doc false
  @spec update_changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def update_changeset(school, attrs) do
    school
    |> cast(attrs, shared_cast_fields())
    |> default_changeset()
  end

  defp default_changeset(changeset) do
    changeset
    |> validate_required([:created_by_id, :email, :name, :public?, :slug])
    |> unique_constraint(:custom_domain)
    |> validate_email(:email)
    |> validate_format(:slug, SchoolUtils.blocked_subdomain_regex(), message: dgettext("errors", "is not allowed"))
    |> validate_format(:privacy_policy, ~r/^https:\/\//, message: dgettext("errors", "must start with https://"))
    |> validate_format(:terms_of_use, ~r/^https:\/\//, message: dgettext("errors", "must start with https://"))
    |> validate_slug(:slug)
    |> validate_unique_slug()
    |> validate_custom_domain()
    |> validate_kind()
    |> validate_allow_guests()
  end

  defp shared_cast_fields do
    [
      :allow_guests?,
      :created_by_id,
      :currency,
      :custom_domain,
      :email,
      :icon,
      :logo,
      :name,
      :privacy_policy,
      :public?,
      :require_confirmation?,
      :terms_of_use,
      :school_id,
      :slug
    ]
  end

  defp validate_unique_slug(changeset) do
    changeset
    |> unsafe_validate_unique(:slug, Zoonk.Repo)
    |> unique_constraint(:slug)
  end

  # Don't allow private schools to allow guests.
  defp validate_allow_guests(changeset) do
    public? = get_field(changeset, :public?)
    allow_guests? = if public?, do: get_field(changeset, :allow_guests?), else: false
    put_change(changeset, :allow_guests?, allow_guests?)
  end

  # Child schools must have a `white_label` kind. A school has a parent school when `school_id` is not `nil`.
  defp validate_kind(changeset) do
    kind = get_field(changeset, :kind)
    school_id = get_field(changeset, :school_id)

    if school_id && kind != :white_label do
      add_error(changeset, :kind, dgettext("errors", "must be white_label"))
    else
      changeset
    end
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
  # For example: `science.app.zoonk.io`, `app.zoonk.io` all have the same `zoonk.io` domain.
  # This is a problem because we use the school's username as a subdomain.
  # So, if a school sets `science.app.zoonk.io` as their custom domain, this would cause a conflict with schools using the `science` username.
  # Hence, we drop the first part of the domain to see if the last parts match any custom domains other schools have.
  defp extract_domain(changeset) do
    custom_domain = get_change(changeset, :custom_domain)
    domain_parts = String.split(custom_domain, ".")

    domain_parts
    # Only drop the first part for domains that have more than one part.
    # Otherwise, we could drop the `zoonk` part from `zoonk.io`, for example.
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
