defmodule ZoonkWeb.TestHelpers.Upload do
  @moduledoc """
  Upload helper functions for tests.
  """
  use ZoonkWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @doc """
  Asserts a file is being uploaded.
  """
  @spec assert_file_upload(Phoenix.LiveView.unsigned_params(), String.t()) :: String.t()
  def assert_file_upload(lv, id) do
    files = get_files()
    input = file_input(lv, "#upload-form-#{id}", :file, files)

    render_upload(input, "robot.png")
  end

  defp get_files do
    [
      %{
        name: "robot.png",
        content:
          [:code.priv_dir(:zoonk), "static", "uploads", "seed", "courses", "robot.png"]
          |> Path.join()
          |> File.read!()
      }
    ]
  end
end
