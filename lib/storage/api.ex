defmodule Zoonk.Storage.StorageAPI do
  @moduledoc """
  Provides a way to upload files to the storage service.
  """
  alias ExAws.S3

  @callback upload(String.t(), String.t()) :: {:ok, term()} | {:error, term()}
  @callback delete(String.t()) :: {:ok, term()} | {:error, term()}

  @doc """
  Uploads a file to the storage service.

  ## Examples

      iex> StorageAPI.upload("path/to/file", "image/webp")
      {:ok, %{}}

      iex> StorageAPI.upload("path/to/file", "image/webp")
      {:error, %{}}
  """
  @spec upload(String.t(), String.t()) :: {:ok, term()} | {:error, term()}
  def upload(file_path, content_type), do: impl().upload(file_path, content_type)

  @doc """
  Deletes a file from the storage service.

  ## Examples

      iex> StorageAPI.delete("key")
      {:ok, %{}}

      iex> StorageAPI.delete("key")
      {:error, %{}}
  """
  @spec delete(String.t()) :: {:ok, term()} | {:error, term()}
  def delete(key), do: impl().delete(key)

  @doc """
  Gets the URL of a file from the storage service.

  ## Examples

      iex> StorageAPI.get_url("key")
      "https://cdn.zoonk.io/bucket/key"
  """
  @spec get_url(String.t()) :: String.t()
  def get_url(key), do: "#{bucket_url()}/#{key}"

  @doc """
  Gets the CDN domain of the storage service.

  ## Examples

      iex> StorageAPI.get_domain()
      "https://cdn.zoonk.io"
  """
  @spec get_domain() :: String.t()
  def get_domain, do: Application.get_env(:zoonk, :storage)[:domain]

  @doc """
  Gets the bucket name of the storage service.

  ## Examples

      iex> StorageAPI.get_bucket()
      "zoonkdev"
  """
  @spec get_bucket() :: String.t()
  def get_bucket, do: Application.get_env(:zoonk, :storage)[:bucket]

  @doc """
  Gets the bucket URL of the storage service.

  ## Examples

      iex> StorageAPI.bucket_url()
      "https://cdn.zoonk.io/zoonkdev"
  """
  @spec bucket_url() :: String.t()
  def bucket_url, do: "#{get_domain()}/#{get_bucket()}"

  # We use this to allow us to mock the storage service in tests
  defp impl, do: Application.get_env(:zoonk, :s3, Zoonk.ExternalStorageAPI)
end

defmodule Zoonk.ExternalStorageAPI do
  @moduledoc false
  alias ExAws.S3
  alias Zoonk.Storage.StorageAPI

  @spec upload(String.t(), String.t()) :: {:ok, term()} | {:error, term()}
  def upload(file_path, content_type) do
    file_path
    |> S3.Upload.stream_file()
    |> S3.upload(StorageAPI.get_bucket(), Path.basename(file_path), content_type: content_type)
    |> ExAws.request()
  end

  @spec delete(String.t()) :: {:ok, term()} | {:error, term()}
  def delete(key) do
    StorageAPI.get_bucket()
    |> S3.delete_object(key)
    |> ExAws.request()
  end
end
