defmodule UneebeeWeb.Shared.ImageOptimizer do
  @moduledoc """
  Uploads an image to [Cloudflare Images](https://www.cloudflare.com/developer-platform/cloudflare-images/).

  It handles variantas and image resizing.

  This code uses Peter Ullrich's solution posted on his [personal blog](https://peterullrich.com/resize-user-provided-images-with-cloudflare).
  """
  require Logger

  @doc """
  Uploads an image to Cloudflare Images.

  ## Examples

      iex> ImageUpload.upload("image.jpg", byte_content, ["courseCover"])
      {:ok, %{"courseCover" => "https://example.com/courseCover/image.jpg"}}
  """
  @spec upload(String.t(), binary()) :: {:ok, map()} | {:error, map()}
  def upload(filename, byte_content) do
    # Build the Multipart payload
    file = Multipart.Part.file_content_field(filename, byte_content, :file, filename: filename)
    multipart = Multipart.add_part(Multipart.new(), file)

    # Build the headers
    content_length = Multipart.content_length(multipart)
    content_type = Multipart.content_type(multipart, "multipart/form-data")

    headers = [
      {"authorization", "Bearer #{bearer_token()}"},
      {"Content-Type", content_type},
      {"Content-Length", to_string(content_length)}
    ]

    # Upload the image to Cloudflare
    api_url()
    |> Req.post(headers: headers, body: Multipart.body_stream(multipart))
    |> handle_result()
  end

  @spec enabled?() :: boolean()
  def enabled?, do: account_id() != nil

  @spec image_url(String.t(), String.t()) :: String.t()
  def image_url(image_id, variant), do: "https://imagedelivery.net/#{account_hash()}/#{image_id}/#{variant}"

  defp handle_result({:ok, %Req.Response{status: 200, body: body}}) do
    %{"result" => %{"id" => id}} = body
    {:ok, id}
  end

  defp handle_result({:error, %Req.Response{status: status, body: body}}) do
    Logger.error("Image Upload failed with #{status}: #{inspect(body)}")
    {:error, body}
  end

  defp api_url, do: "https://api.cloudflare.com/client/v4/accounts/#{account_id()}/images/v1"
  defp account_id, do: Application.get_env(:uneebee, :cloudflare)[:account_id]
  defp bearer_token, do: Application.get_env(:uneebee, :cloudflare)[:api_token]
  defp account_hash, do: Application.get_env(:uneebee, :cloudflare)[:account_hash]
end
