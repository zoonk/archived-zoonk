defmodule ZoonkWeb.TestHelpers.Upload do
  @moduledoc """
  Upload helper functions for tests.
  """
  use ZoonkWeb.ConnCase, async: true

  import Mox
  import Phoenix.LiveViewTest

  alias Zoonk.Storage.StorageAPIMock

  @file_name "16.png"

  @doc """
  Asserts a file is being uploaded.
  """
  @spec assert_file_upload(Phoenix.LiveView.unsigned_params(), String.t()) :: String.t()
  def assert_file_upload(lv, id) do
    files = get_files()
    input = file_input(lv, "#upload-form-#{id}", :file, files)

    assert render_upload(input, @file_name)
  end

  @doc """
  Mocks the storage API for tests.
  """
  @spec mock_storage() :: :ok
  def mock_storage do
    expect(StorageAPIMock, :presigned_url, fn _entry, _folder -> {"https://test.com", @file_name} end)
    expect(StorageAPIMock, :optimize!, fn _key, _size -> :ok end)
  end

  @doc """
  Returns the mock file name
  """
  @spec uploaded_file_name() :: String.t()
  def uploaded_file_name, do: @file_name

  defp get_files do
    [
      %{
        name: @file_name,
        content:
          [:code.priv_dir(:zoonk), "static", "favicon", @file_name]
          |> Path.join()
          |> File.read!()
      }
    ]
  end
end
