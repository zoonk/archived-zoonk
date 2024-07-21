defmodule Zoonk.Storage.StorageAPIBehaviour do
  @moduledoc false
  alias Phoenix.LiveView.UploadEntry

  @callback delete(String.t()) :: {:ok, term()} | {:error, term()}
  @callback presigned_url(UploadEntry.t()) :: {String.t(), String.t()}
end

defmodule Zoonk.Storage.StorageAPI do
  @moduledoc false
  @behaviour Zoonk.Storage.StorageAPIBehaviour

  alias ExAws.S3
  alias Phoenix.LiveView.UploadEntry

  @spec delete(String.t()) :: {:ok, term()} | {:error, term()}
  def delete(key) do
    Zoonk.Storage.get_bucket()
    |> S3.delete_object(key)
    |> ExAws.request()
  end

  @spec presigned_url(UploadEntry.t()) :: {String.t(), String.t()}
  def presigned_url(%UploadEntry{client_name: client_name, client_type: client_type}) do
    config = ExAws.Config.new(:s3)
    bucket = Zoonk.Storage.get_bucket()
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
