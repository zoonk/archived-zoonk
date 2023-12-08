defmodule Uneebee.Organizations do
  @moduledoc """
  Organizations context.
  """
  import Ecto.Query, warn: false

  alias Uneebee.Accounts.User
  alias Uneebee.Content.Course
  alias Uneebee.Content.CourseUser
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
    School.update_changeset(school, attrs)
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
    %School{} |> School.create_changeset(attrs) |> Repo.insert()
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
      |> Ecto.Multi.insert(:school, School.create_changeset(%School{}, attrs))
      |> Ecto.Multi.run(:school_user, fn _repo, %{school: school} -> create_school_user(school, user, school_user_attrs) end)

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
  Gets a single school.

  Raises `Ecto.NoResultsError` if the School does not exist.

  ## Examples

      iex> get_school!(123)
      %School{}

      iex> get_school!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_school!(non_neg_integer()) :: School.t()
  def get_school!(id), do: Repo.get!(School, id)

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
  Update a school user.

  ## Examples

      iex> update_school_user(school_user_id, %{role: :student})
      {:ok, %SchoolUser{}}

      iex> update_school_user(school_user_id, %{role: :invalid})
      {:error, %Ecto.Changeset{}}
  """
  @spec update_school_user(non_neg_integer(), map()) :: school_user_changeset()
  def update_school_user(school_user_id, attrs \\ %{}) do
    school_user_id |> get_school_user!() |> SchoolUser.changeset(attrs) |> Repo.update()
  end

  @doc """
  Get a school user by id.

  ## Examples

      iex> get_school_user!(123)
      %SchoolUser{}

      iex> get_school_user!(456)
      ** (Ecto.NoResultsError)
  """
  @spec get_school_user!(non_neg_integer()) :: SchoolUser.t()
  def get_school_user!(id), do: Repo.get!(SchoolUser, id)

  @doc """
  Get a user from a school given their usernames.

  ## Examples

      iex> get_school_user("uneebee", "will")
      %SchoolUser{}

      iex> get_school_user("uneebee", "invalid")
      nil
  """
  @spec get_school_user(String.t(), String.t(), list()) :: SchoolUser.t() | nil
  def get_school_user(school_slug, user_username, opts \\ []) do
    preload = Keyword.get(opts, :preload, [:school, :user])

    query =
      from(school_user in SchoolUser,
        join: school in assoc(school_user, :school),
        join: user in assoc(school_user, :user),
        where: school.slug == ^school_slug,
        where: user.username == ^user_username,
        preload: ^preload
      )

    Repo.one(query)
  end

  @doc """
  Search school user.

  Search a school user by `first_name`, `last_name`, `username`, or `email`.

  ## Examples
      iex> search_school_users(school_id, "will")
      [%SchoolUser{}, ...]

      iex> search_school_users(school_id ,"will ceolin")
      [%SchoolUser{}, ...]

      iex> search_school_users(school_id, "will@zoonk.org")
      [%SchoolUser{}, ...]

      iex> search_school_users(school_id, "invalid")
      []
  """
  @spec search_school_users(non_neg_integer(), String.t()) :: [SchoolUser.t()]
  def search_school_users(school_id, term) do
    search_term = "%#{term}%"
    combined_name_search_term = search_term |> String.split(" ") |> Enum.join(" ")

    SchoolUser
    |> join(:inner, [su], u in User, on: su.user_id == u.id)
    |> where([su, u], su.school_id == ^school_id)
    |> where(
      [su, u],
      ilike(u.username, ^search_term) or
        ilike(u.email, ^search_term) or
        ilike(u.first_name, ^search_term) or
        ilike(u.last_name, ^search_term) or
        ilike(fragment("? || ' ' || ?", u.first_name, u.last_name), ^combined_name_search_term)
    )
    |> preload([su, u], user: u)
    |> Repo.all()
  end

  @doc """
  Gets a single school based on the `host` value.

  ## Examples

      iex> get_school_by_host!("unisc.uneebee.com")
      %School{}

      iex> get_school_by_host!("interactive.rug.nl")
      %School{}

      iex> get_school_by_host!("nonexisting.com")
      nil
  """
  @spec get_school_by_host!(String.t()) :: School.t() | nil
  def get_school_by_host!(host) do
    [subdomain | domain_parts] = String.split(host, ".")
    domain = Enum.join(domain_parts, ".")

    school =
      School
      # Try to find a match for either the full `host` value or the `domain` without the subdomain.
      |> where([school], school.custom_domain in [^host, ^domain])
      |> Repo.one()

    # If it matches the `domain` value, we need to check if the subdomain is a valid slug.
    # For example, the `slug` should exist but also belong to the school whose `custom_domain` is match.
    # See the `get_school_by_host!/1` tests for examples.
    if school && school.custom_domain == domain do
      Repo.get_by!(School, slug: subdomain, school_id: school.id)
    else
      school
    end
  end

  @doc """
  Get the app school.

  That's the main school used for setting up the app. All other schools are created under this one.

  ## Examples

      iex> get_app_school!(%School{})
      %School{}
  """
  @spec get_app_school!(School.t()) :: School.t() | nil
  def get_app_school!(%School{school_id: nil} = school), do: school
  def get_app_school!(%School{school_id: school_id}), do: get_school!(school_id)
  def get_app_school!(nil), do: nil

  @doc """
  List schools.

  Returns all schools that belong to another school.

  ## Examples

      iex> list_schools(school_id)
      [%School{}, ...]
  """
  @spec list_schools(integer(), list()) :: [School.t()]
  def list_schools(school_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    offset = Keyword.get(opts, :offset, 0)

    School
    |> where([s], s.school_id == ^school_id)
    |> order_by(desc: :updated_at)
    |> offset(^offset)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Get the number of users in a school.

  ## Examples

      iex> get_school_users_count(school)
      10
  """
  @spec get_school_users_count(School.t()) :: non_neg_integer()
  def get_school_users_count(school) do
    SchoolUser |> where([su], su.school_id == ^school.id) |> Repo.aggregate(:count)
  end

  @doc """
  Gets the number of users in a school based on their role.

  ## Examples

      iex> get_school_users_count(school, :manager)
      10
  """
  @spec get_school_users_count(School.t(), atom()) :: non_neg_integer()
  def get_school_users_count(school, role) do
    SchoolUser |> where([su], su.school_id == ^school.id and su.role == ^role) |> Repo.aggregate(:count)
  end

  @doc """
  List all users for a school according to their role.

  ## Examples

      iex> list_school_users(school_id)
      [%SchoolUser{}, ...]

      iex> list_school_users(school_id, limit: 20, offset: 0)
      [%SchoolUser{}, ...]
  """
  @spec list_school_users(non_neg_integer(), list()) :: [SchoolUser.t()]
  def list_school_users(school_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)
    role = Keyword.get(opts, :role, nil)

    SchoolUser
    |> where([su], su.school_id == ^school_id)
    |> maybe_filter_by_role(role)
    |> order_by([su], asc: su.approved?)
    |> order_by([su], desc: su.updated_at)
    |> limit(^limit)
    |> offset(^offset)
    |> preload([su], [:approved_by, :user])
    |> Repo.all()
  end

  defp maybe_filter_by_role(query, nil), do: query
  defp maybe_filter_by_role(query, role), do: where(query, [su], su.role == ^role)

  @doc """
  Approves a school user.

  ## Examples

      iex> approve_school_user(school_user_id)
      {:ok, %SchoolUser{}}

      iex> approve_school_user(school_user_id)
      {:error, %Ecto.Changeset{}}
  """
  @spec approve_school_user(integer(), integer()) :: school_user_changeset()
  def approve_school_user(school_user_id, approved_by_id) do
    attrs = %{approved?: true, approved_by_id: approved_by_id, approved_at: DateTime.utc_now()}
    SchoolUser |> Repo.get(school_user_id) |> SchoolUser.changeset(attrs) |> Repo.update()
  end

  @doc """
  Deletes a school user.

  ## Examples

      iex> delete_school_user(school_user_id)
      {:ok, %SchoolUser{}}

      iex> delete_school_user(school_user_id)
      {:error, %Ecto.Changeset{}}
  """
  @spec delete_school_user(integer()) :: school_user_changeset()
  def delete_school_user(school_user_id) do
    school_user = Repo.get(SchoolUser, school_user_id)

    Repo.transaction(fn ->
      Repo.delete(school_user)
      delete_course_users(school_user.user_id, school_user.school_id)
    end)
  end

  defp delete_course_users(user_id, school_id) do
    CourseUser
    |> where([cu], cu.user_id == ^user_id)
    |> join(:inner, [cu], c in assoc(cu, :course), on: c.school_id == ^school_id)
    |> Repo.delete_all()
  end

  @doc """
  Gets the number of courses a school has.

  ## Examples

      iex> get_courses_count(school)
      10
  """
  @spec get_courses_count(School.t()) :: non_neg_integer()
  def get_courses_count(school) do
    Course |> where([c], c.school_id == ^school.id) |> Repo.aggregate(:count)
  end
end
