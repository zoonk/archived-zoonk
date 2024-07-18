defmodule Zoonk.Storage do
  @moduledoc """
  The Storage context.
  """

  import Ecto.Query, warn: false

  alias Zoonk.Repo
  alias Zoonk.Storage.SchoolObject

  @type school_object_changeset :: {:ok, SchoolObject.t()} | {:error, Ecto.Changeset.t()}

  @doc """
  Creates a school object.

  ## Examples

      iex> create_school_object(%{field: "value"})
      {:ok, %SchoolObject{}}

      iex> create_school_object(%{field: "value"})
      {:error, %Ecto.Changeset{}}
  """
  @spec create_school_object(map()) :: school_object_changeset()
  def create_school_object(attrs \\ %{}) do
    %SchoolObject{}
    |> SchoolObject.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a school object.

  ## Examples

      iex> update_school_object("key", %{field: "new_value"})
      {:ok, %SchoolObject{}}

      iex> update_school_object("key", %{field: "new_value"})
      {:error, %Ecto.Changeset{}}
  """
  @spec update_school_object(String.t(), map()) :: school_object_changeset()
  def update_school_object(key, attrs \\ %{}) do
    SchoolObject
    |> Repo.get_by(key: key)
    |> SchoolObject.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a school object.

  ## Examples

      iex> delete_school_object("key")
      {:ok, %SchoolObject{}}

      iex> delete_school_object("key")
      {:error, %Ecto.Changeset{}}
  """
  @spec delete_school_object(String.t()) :: school_object_changeset()
  def delete_school_object(key) do
    SchoolObject
    |> Repo.get_by(key: key)
    |> Repo.delete()
  end
end
