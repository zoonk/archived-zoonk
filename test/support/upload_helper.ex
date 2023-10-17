defmodule UneebeeWeb.TestHelpers.Upload do
  @moduledoc """
  Upload helper functions for tests.
  """
  use UneebeeWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @doc """
  Asserts a file is being uploaded.
  """
  @spec assert_file_upload(Phoenix.LiveView.live(), String.t()) :: boolean()
  def assert_file_upload(lv, id) do
    files = get_files()
    input = file_input(lv, "#upload-form-#{id}", :file, files)

    assert render_upload(input, "robot.png") =~ "Uploading file: 100% concluded"

    lv |> element("#upload-form-#{id}") |> render_submit()
  end

  defp get_files do
    [
      %{
        name: "robot.png",
        content:
          [:code.priv_dir(:uneebee), "static", "uploads", "seed", "courses", "robot.png"]
          |> Path.join()
          |> File.read!()
      }
    ]
  end
end
