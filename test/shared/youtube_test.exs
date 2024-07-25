defmodule ZoonkWeb.SharedYoutubeTest do
  use Zoonk.DataCase, async: true

  import Zoonk.Shared.YouTube

  describe "extract_video_id/1" do
    test "extracts the YouTube video ID from a URL" do
      # standard url
      assert extract_video_id("https://www.youtube.com/watch?v=12345678901") == "12345678901"
      assert extract_video_id("http://www.youtube.com/watch?v=12345678901") == "12345678901"
      assert extract_video_id("https://youtube.com/watch?v=12345678901") == "12345678901"
      assert extract_video_id("www.youtube.com/watch?v=12345678901") == "12345678901"
      assert extract_video_id("youtube.com/watch?v=12345678901") == "12345678901"

      # short url
      assert extract_video_id("https://youtu.be/12345678901") == "12345678901"
      assert extract_video_id("http://youtu.be/12345678901") == "12345678901"
      assert extract_video_id("youtu.be/12345678901") == "12345678901"

      # embedded url
      assert extract_video_id("https://www.youtube.com/embed/12345678901") == "12345678901"
      assert extract_video_id("http://www.youtube.com/embed/12345678901") == "12345678901"
      assert extract_video_id("https://youtube.com/embed/12345678901") == "12345678901"
      assert extract_video_id("www.youtube.com/embed/12345678901") == "12345678901"
      assert extract_video_id("youtube.com/embed/12345678901") == "12345678901"

      # alternative formats
      assert extract_video_id("https://www.youtube.com/v/12345678901") == "12345678901"
      assert extract_video_id("http://www.youtube.com/v/12345678901") == "12345678901"
      assert extract_video_id("https://youtube.com/v/12345678901") == "12345678901"
      assert extract_video_id("www.youtube.com/v/12345678901") == "12345678901"
      assert extract_video_id("youtube.com/v/12345678901") == "12345678901"

      # alternative url parameters
      assert extract_video_id("https://www.youtube.com/watch?feature=player_embedded&v=12345678901") == "12345678901"
      assert extract_video_id("http://www.youtube.com/watch?feature=player_embedded&v=12345678901") == "12345678901"
      assert extract_video_id("https://youtube.com/watch?feature=player_embedded&v=12345678901") == "12345678901"
      assert extract_video_id("www.youtube.com/watch?feature=player_embedded&v=12345678901") == "12345678901"
      assert extract_video_id("youtube.com/watch?feature=player_embedded&v=12345678901") == "12345678901"

      # playlist with specific video
      assert extract_video_id("https://www.youtube.com/watch?v=12345678901&list=12345678901") == "12345678901"
      assert extract_video_id("http://www.youtube.com/watch?v=12345678901&list=12345678901") == "12345678901"
      assert extract_video_id("https://youtube.com/watch?v=12345678901&list=12345678901") == "12345678901"
      assert extract_video_id("www.youtube.com/watch?v=12345678901&list=12345678901") == "12345678901"
      assert extract_video_id("youtube.com/watch?v=12345678901&list=12345678901") == "12345678901"

      # invalid url
      assert extract_video_id("invalid") == nil
    end
  end

  describe "remove_from_string/1" do
    test "removes a YouTube URL from a string" do
      assert remove_from_string("watch the video: https://youtu.be/12345678901") == "watch the video:"
      assert remove_from_string("https://youtu.be/12345678901 watch the video") == "watch the video"
    end
  end
end
