defmodule Uneebee.Organizations do
  @moduledoc """
  Organizations context.
  """
  alias Uneebee.Organizations.School
  alias Uneebee.Repo

  @type school_changeset :: {:ok, School.t()} | {:error, Ecto.Changeset.t()} | {:error, String.t()}

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
end
