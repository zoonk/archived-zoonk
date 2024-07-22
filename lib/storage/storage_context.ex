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

      iex> Storage.delete_object("key")
      {:ok, %{}}

      iex> Storage.delete_object("key")
      {:error, %{}}
  """
  @spec delete_object(String.t()) :: {:ok, term()} | {:error, term()} | school_object_changeset()
  def delete_object(key) do
    case storage_module().delete(key) do
      {:ok, _} ->
        delete_school_object(key)

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Generates a presigned URL for a file upload.

  ## Examples

      iex> Storage.presigned_url(%UploadEntry{}, "123/schools/logo")
      {"https://...", "123/schools/logo/123.webp"}
  """
  @spec presigned_url(Phoenix.LiveView.UploadEntry.t(), String.t()) :: {String.t(), String.t()}
  def presigned_url(entry, folder) do
    {url, key} = storage_module().presigned_url(entry, folder)

    file_attrs = %{key: key, content_type: entry.client_type, size_kb: div(entry.client_size, 1000)}

    # get the correct table and id that should be used when adding a school object
    db_attrs = folder |> String.split("/") |> school_object_attrs_from_folder()

    db_attrs |> Map.merge(file_attrs) |> create_school_object()

    {url, key}
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
  Generates folder name.

  We use a standard format for folder names to avoid conflicts and make it easier to manage,
  especially when we need to update school objects.

  ## Examples

      iex> Storage.generate_folder_name(1, "table_name", 456, "column_name")
      "1/table_name/456/column_name"
  """
  @spec generate_folder_name(non_neg_integer(), String.t(), non_neg_integer(), String.t()) :: String.t()
  def generate_folder_name(school_id, table_name, item_id, column_name) do
    "#{school_id}/#{table_name}/#{item_id}/#{column_name}"
  end

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
    update_school_object(key, %{size_kb: storage_module().get_object_size_in_kb!(key)})
  end

  defp school_object_attrs_from_folder([school_id, "courses", course_id, _column]), do: %{school_id: school_id, course_id: course_id}
  defp school_object_attrs_from_folder([school_id, "lessons", lesson_id, _column]), do: %{school_id: school_id, lesson_id: lesson_id}
  defp school_object_attrs_from_folder([school_id, "lesson_steps", lesson_step_id, _column]), do: %{school_id: school_id, lesson_step_id: lesson_step_id}
  defp school_object_attrs_from_folder([school_id, "step_options", step_option_id, _column]), do: %{school_id: school_id, step_option_id: step_option_id}
  defp school_object_attrs_from_folder([school_id, _table, _id, _column]), do: %{school_id: school_id}

  defp storage_module, do: Application.get_env(:zoonk, :storage_api, Zoonk.Storage.StorageAPI)
end
