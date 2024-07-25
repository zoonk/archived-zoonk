# credo:disable-for-this-file Credo.Check.Readability.Specs

defmodule ZoonkWeb.Components.YouTube do
  @moduledoc """
  YouTube components.
  """
  use Phoenix.Component

  import ZoonkWeb.Gettext

  alias Zoonk.Shared.YouTube

  @doc """
  Renders a YouTube video player.
  """
  attr :content, :string, default: nil, doc: "a string containing the YouTube video URL"

  def youtube(assigns) do
    ~H"""
    <div :if={youtube_id(@content)} class="aspect-video">
      <iframe
        src={"https://www.youtube-nocookie.com/embed/#{youtube_id(@content)}"}
        title={gettext("YouTube video player")}
        frameborder="0"
        allow="accelerometer; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
        referrerpolicy="strict-origin-when-cross-origin"
        allowfullscreen
        class="h-full w-full rounded-lg"
      >
      </iframe>
    </div>
    """
  end

  defp youtube_id(content), do: YouTube.extract_video_id(content)
end
