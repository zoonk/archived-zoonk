defmodule Zoonk.Storage.ImageOptimizer do
  @moduledoc """
  Background job to optimize images.
  """
  use Oban.Worker

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"key" => key} = args}) do
    Logger.info("Optimizing image: #{key}")

    # If a NIF crashes, it can bring down the BEAM virtual machine
    # https://hexdocs.pm/image/readme.html#security-considerations
    # This could be used by a malicious user to crash the server
    # So we run it in a separate machine using FLAME. This way, if the NIF crashes,
    # it won't affect the main server
    FLAME.call(Zoonk.FLAME.ImageOptimization, fn ->
      Zoonk.Storage.optimize!(key, args["size"] || 500)
    end)

    Logger.info("Optimized image: #{key}")
    :ok
  end
end
