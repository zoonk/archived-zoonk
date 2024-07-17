defmodule ZoonkWeb.Shared.Storage do
  @moduledoc """
  Provides a way to upload files to the storage service.
  """

  alias ExAws.S3

  @doc """
  Uploads a file to the storage service.

  ## Examples

      iex> Storage.upload("path/to/file")
      {:ok, %{}}

      iex> Storage.upload("path/to/file")
      {:error, %{}}
  """
  @spec upload(String.t()) :: {:ok, term()} | {:error, term()}
  def upload(file_path) do
    file_path
    |> S3.Upload.stream_file()
    |> S3.upload(get_bucket(), Path.basename(file_path))
    |> ExAws.request()
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
    get_bucket()
    |> S3.delete_object(key)
    |> ExAws.request()
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

  defp get_bucket, do: Application.get_env(:zoonk, :storage)[:bucket]
  defp bucket_url, do: "#{get_domain()}/#{get_bucket()}"
end
