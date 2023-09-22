defmodule Uneebee.Organizations do
  @moduledoc """
  Organizations context.
  """
  import Ecto.Query, warn: false

  alias Uneebee.Accounts.User
  alias Uneebee.Organizations.School
  alias Uneebee.Organizations.SchoolUser
  alias Uneebee.Repo

  @type school_changeset :: {:ok, School.t()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}
  @type school_user_changeset :: {:ok, SchoolUser.t()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking school changes.

  ## Examples

      iex> change_school(school)
      %Ecto.Changeset{data: %School{}}

  """
  @spec change_school(School.t(), map()) :: Ecto.Changeset.t()
  def change_school(%School{} = school, attrs \\ %{}) do
    School.changeset(school, attrs)
  end

  @doc """
  Creates a school.

  ## Examples

      iex> create_school(%{field: value})
      {:ok, %School{}}

      iex> create_school(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  @spec create_school(map()) :: school_changeset()
  def create_school(attrs \\ %{}) do
    %School{} |> change_school(attrs) |> Repo.insert()
  end

  @doc """
  Creates a school and adds a user as school manager.

  ## Examples

      iex> create_school_and_manager(user, %{field: value})
      {:ok, %School{}}

      iex> create_school_and_manager(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_school_and_manager(User.t(), map()) :: school_changeset()
  def create_school_and_manager(%User{} = user, attrs \\ %{}) do
    school_user_attrs = %{role: :manager, approved?: true, approved_by_id: user.id, approved_at: DateTime.utc_now()}

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:school, School.changeset(%School{}, attrs))
      |> Ecto.Multi.run(:school_user, fn _repo, %{school: school} ->
        create_school_user(school, user, school_user_attrs)
      end)

    case Repo.transaction(multi) do
      {:ok, %{school: school}} -> {:ok, school}
      {:error, _failed_operation, changeset, _changes_so_far} -> {:error, changeset}
    end
  end

  @doc """
  Updates a school.

  ## Examples

      iex> update_school(school, %{field: value})
      {:ok, %School{}}

      iex> update_school(school, %{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  @spec update_school(School.t(), map()) :: school_changeset()
  def update_school(%School{} = school, attrs \\ %{}) do
    school |> change_school(attrs) |> Repo.update()
  end

  @doc """
  Get a school by slug.

  ## Examples

      iex> get_school_by_slug!("slug")
      %School{}

      iex> get_school_by_slug!("invalid_slug")
      ** (Ecto.NoResultsError)
  """
  @spec get_school_by_slug!(String.t()) :: School.t()
  def get_school_by_slug!(slug) do
    Repo.get_by!(School, slug: slug)
  end

  @doc """
  Checks if there's a school configured.

  ## Examples

      iex> school_configured?()
      true

      iex> school_configured?()
      false
  """
  @spec school_configured?() :: boolean()
  def school_configured? do
    Repo.exists?(School)
  end

  @doc """
  Adds a user to a school.

  ## Examples

      iex> create_school_user(school, user, %{role: :student})
      {:ok, %SchoolUser{}}

      iex> create_school_user(school, user, %{role: :invalid})
      {:error, %Ecto.Changeset{}}
  """
  @spec create_school_user(School.t(), User.t(), map()) :: school_user_changeset()
  def create_school_user(%School{} = school, %User{} = user, attrs \\ %{}) do
    school_user_attrs = Enum.into(attrs, %{user_id: user.id, school_id: school.id})
    %SchoolUser{} |> SchoolUser.changeset(school_user_attrs) |> Repo.insert()
  end

  @doc """
  Get a school user given a school slug and a user username.

  ## Examples

      iex> get_school_user_by_slug_and_username("slug", "username")
      %SchoolUser{}

      iex> get_school_user_by_slug_and_username("invalid_slug", "invalid_username")
      nil
  """
  @spec get_school_user_by_slug_and_username(String.t(), String.t()) :: SchoolUser.t() | nil
  def get_school_user_by_slug_and_username(slug, username) do
    SchoolUser
    |> join(:inner, [su], s in assoc(su, :school), on: s.slug == ^slug)
    |> join(:inner, [su], u in assoc(su, :user), on: u.username == ^username)
    |> Repo.one()
  end
end
