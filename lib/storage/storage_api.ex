defmodule Zoonk.Storage.StorageAPIBehaviour do
  @moduledoc false
  alias Phoenix.LiveView.UploadEntry

  @callback delete(String.t()) :: {:ok, term()} | {:error, term()}
  @callback presigned_url(UploadEntry.t()) :: {String.t(), String.t()}
  @callback optimize!(String.t(), integer()) :: term()
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

  @spec optimize!(String.t(), integer()) :: term()
  def optimize!(key, size) do
    %{body: body} = download_image!(key)
    thumbnail = body |> Image.from_binary!() |> Image.thumbnail!(size)
    upload_image!(thumbnail, key)
  end

  defp download_image!(key) do
    Zoonk.Storage.get_bucket()
    |> S3.get_object(key)
    |> ExAws.request!()
  end

  defp upload_image!(thumbnail, key) do
    thumbnail
    |> Image.stream!(suffix: ".webp")
    |> S3.upload(Zoonk.Storage.get_bucket(), key, content_type: "image/webp")
    |> ExAws.request!()
  end
end
