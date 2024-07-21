defmodule Zoonk.Storage.ImageOptimizer do
  @moduledoc """
  Background job to optimize images.
  """
  use Oban.Worker

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"key" => key} = args}) do
    Logger.info("Optimizing image: #{key}")
    Zoonk.Storage.optimize!(key, args["size"] || 500)
    Logger.info("Optimized image: #{key}")
    :ok
  end
end
