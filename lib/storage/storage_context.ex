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

  @doc """
  Deletes a file from the storage service.

  ## Examples

      iex> Storage.delete("key")
      {:ok, %{}}

      iex> Storage.delete("key")
      {:error, %{}}
  """
  @spec delete(String.t()) :: {:ok, term()} | {:error, term()}
  def delete(key) do
    storage_module().delete(key)
  end

  @doc """
  Generates a presigned URL for a file upload.

  ## Examples

      iex> Storage.presigned_url(%UploadEntry{})
      "https://..."
  """
  @spec presigned_url(Phoenix.LiveView.UploadEntry.t()) :: {String.t(), String.t()}
  def presigned_url(entry) do
    storage_module().presigned_url(entry)
  end

  @doc """
  Gets the URL of a file from the storage service.

  ## Examples

      iex> Storage.get_url("key")
      "https://cdn.zoonk.io/bucket/key"
  """
  @spec get_url(String.t()) :: String.t()
  def get_url(key), do: "#{bucket_url()}/#{key}"

  @doc """
  Gets the CDN domain of the storage service.

  ## Examples

      iex> Storage.get_domain()
      "https://cdn.zoonk.io"
  """
  @spec get_domain() :: String.t()
  def get_domain, do: Application.get_env(:zoonk, :storage)[:domain]

  @doc """
  Gets the bucket name of the storage service.

  ## Examples

      iex> Storage.get_bucket()
      "zoonkdev"
  """
  @spec get_bucket() :: String.t()
  def get_bucket, do: Application.get_env(:zoonk, :storage)[:bucket]

  @doc """
  Gets the bucket URL of the storage service.

  ## Examples

      iex> Storage.bucket_url()
      "https://cdn.zoonk.io/zoonkdev"
  """
  @spec bucket_url() :: String.t()
  def bucket_url, do: "#{get_domain()}/#{get_bucket()}"

  @doc """
  Optimize an image.
  """
  @spec optimize!(String.t(), integer()) :: term()
  def optimize!(key, size) do
    storage_module().optimize!(key, size)
  end

  defp storage_module, do: Application.get_env(:zoonk, :storage_api, Zoonk.Storage.StorageAPI)
end
