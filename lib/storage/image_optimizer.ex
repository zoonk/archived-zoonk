defmodule Zoonk.Storage.ImageOptimizer do
  @moduledoc """
  Background job to optimize images.
  """
  use Oban.Worker

  alias ExAws.S3
  alias Zoonk.Storage.StorageAPI

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"key" => key} = args}) do
    Logger.info("Optimizing image: #{key}")
    optimize!(key, args["size"] || 500)
    Logger.info("Optimized image: #{key}")
    :ok
  end

  defp optimize!(key, size) do
    %{body: body} = download_image!(key)
    thumbnail = body |> Image.from_binary!() |> Image.thumbnail!(size)
    upload_image!(thumbnail, key)
  end

  defp download_image!(key), do: StorageAPI.get_bucket() |> S3.get_object(key) |> ExAws.request!()

  defp upload_image!(thumbnail, key) do
    thumbnail
    |> Image.stream!(suffix: ".webp")
    |> S3.upload(StorageAPI.get_bucket(), key, content_type: "image/webp")
    |> ExAws.request!()
  end
end
