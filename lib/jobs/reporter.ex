defmodule Zoonk.Jobs.Reporter do
  @moduledoc """
  Report Oban job errors to third-party services like Sentry.
  """

  @spec attach() :: :ok | {:error, :already_exists}
  def attach do
    :telemetry.attach("oban-errors", [:oban, :job, :exception], &__MODULE__.handle_event/4, [])
  end

  @spec handle_event([atom()], map(), map(), any()) :: Sentry.send_result()
  def handle_event([:oban, :job, :exception], measure, meta, _) do
    extra =
      meta.job
      |> Map.take([:id, :args, :meta, :queue, :worker])
      |> Map.merge(measure)

    Sentry.capture_exception(meta.reason, stacktrace: meta.stacktrace, extra: extra)
  end
end
