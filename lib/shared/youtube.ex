defmodule ZoonkWeb.Shared.YouTube do
  @moduledoc """
  Handle YouTube videos.
  """

  @youtube_regex ~r/(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=|.+&v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})/

  @doc """
  Extracts the YouTube video ID from a URL.

    ## Examples
    iex> YouTube.extract_video_id("https://www.youtube.com/watch?v=12345678901")
    "12345678901"

    iex> YouTube.extract_video_id("https://youtu.be/12345678901")
    "12345678901"

    iex> YouTube.extract_video_id("invalid")
    nil
  """
  @spec extract_video_id(String.t()) :: String.t() | nil
  def extract_video_id(url) do
    case Regex.run(@youtube_regex, url) do
      [_cap, video_id] -> video_id
      _str -> nil
    end
  end

  @doc """
  Remove a YouTube URL from a string.

    ## Examples
    iex> YouTube.remove_from_string("watch the video: https://youtu.be/12345678901")
    "watch the video:"

    iex> YouTube.remove_from_string("https://youtu.be/12345678901 watch the video")
    "watch the video"
  """
  @spec remove_from_string(String.t()) :: String.t()
  def remove_from_string(string) do
    @youtube_regex |> Regex.replace(string, "") |> String.trim()
  end
end
