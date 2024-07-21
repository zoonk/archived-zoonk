defmodule Zoonk.Storage.StorageAPI do
  @moduledoc """
  Provides a way to upload files to the storage service.
  """
  alias ExAws.S3
  alias Phoenix.LiveView.UploadEntry

  @callback delete(String.t()) :: {:ok, term()} | {:error, term()}
  @callback presigned_url(UploadEntry.t()) :: {String.t(), String.t()}

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
  Generates a presigned URL for a file upload.

  ## Examples

      iex> StorageAPI.presigned_url(%UploadEntry{})
      "https://..."
  """
  @spec presigned_url(UploadEntry.t()) :: {String.t(), String.t()}
  def presigned_url(entry), do: impl().presigned_url(entry)

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
  alias Phoenix.LiveView.UploadEntry
  alias Zoonk.Storage.StorageAPI

  @spec delete(String.t()) :: {:ok, term()} | {:error, term()}
  def delete(key) do
    StorageAPI.get_bucket()
    |> S3.delete_object(key)
    |> ExAws.request()
  end

  @spec presigned_url(UploadEntry.t()) :: {String.t(), String.t()}
  def presigned_url(%UploadEntry{client_name: client_name, client_type: client_type}) do
    config = ExAws.Config.new(:s3)
    bucket = StorageAPI.get_bucket()
    timestamp = DateTime.to_unix(DateTime.utc_now())
    key = "#{timestamp}_#{client_name}"

    {:ok, url} =
      ExAws.S3.presigned_url(config, :put, bucket, key,
        expires_in: 3600,
        query_params: [{"Content-Type", client_type}]
      )

    {url, key}
  end
end
