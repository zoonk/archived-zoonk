# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule UneebeeWeb.Shared.CloudStorage do
  @moduledoc """
  Below is code from Chris McCord, modified for Cloudflare R2

  https://gist.github.com/chrismccord/37862f1f8b1f5148644b75d20d1cb073

  This module also uses mekusigjinn's solution posted on the Elixir Forum:
  https://elixirforum.com/t/heres-how-to-upload-to-cloudflare-r2-tweaks-from-original-s3-implementation-code/58686
  """
  @one_hour_seconds 3600

  @doc """
    Returns `{:ok, presigned_url}` where `presigned_url` is a url string

  """
  @spec presigned_put(map(), list()) :: {:ok, String.t()}
  def presigned_put(config, opts) do
    key = Keyword.fetch!(opts, :key)
    expires_in = Keyword.get(opts, :expires_in, @one_hour_seconds)
    encoded_key = URI.encode(key)
    uri = "#{config.url}/#{encoded_key}"

    url =
      :aws_signature.sign_v4_query_params(
        config.access_key_id,
        config.secret_access_key,
        config.region,
        "s3",
        :calendar.universal_time(),
        "PUT",
        uri,
        ttl: expires_in,
        uri_encode_path: false,
        body_digest: "UNSIGNED-PAYLOAD"
      )

    {:ok, url}
  end

  @doc """
    Returns `{:ok, presigned_url}` where `presigned_url` is a url string
    ## NOTE - I haven't actually tested this but the gist of the idea is correct.
  """
  @spec presigned_get(map(), list()) :: {:ok, String.t()}
  def presigned_get(config, opts) do
    key = Keyword.fetch!(opts, :key)
    expires_in = Keyword.get(opts, :expires_in, @one_hour_seconds)
    encoded_key = URI.encode(key)
    uri = "#{config.url}/#{encoded_key}"

    url =
      :aws_signature.sign_v4_query_params(
        config.access_key_id,
        config.secret_access_key,
        config.region,
        "s3",
        :calendar.universal_time(),
        "GET",
        uri,
        ttl: expires_in,
        uri_encode_path: false,
        body_digest: "UNSIGNED-PAYLOAD"
      )

    {:ok, url}
  end

  def bucket, do: storage()[:bucket]
  def bucket_url, do: storage()[:bucket_url]
  def cdn_url, do: storage()[:cdn_url]
  def csp_connect_src, do: storage()[:csp_connect_src]
  def access_key_id, do: storage()[:access_key_id]
  def secret_access_key, do: storage()[:secret_access_key]

  defp storage, do: Application.get_env(:uneebee, :storage)
end
