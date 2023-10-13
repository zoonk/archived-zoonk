defmodule Uneebee.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      UneebeeWeb.Telemetry,
      # Start the Ecto repository
      Uneebee.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Uneebee.PubSub},
      # Start Finch
      {Finch, name: Uneebee.Finch},
      # Start the Endpoint (http/https)
      UneebeeWeb.Endpoint
      # Start a worker by calling: Uneebee.Worker.start_link(arg)
      # {Uneebee.Worker, arg}
    ]

    # Sentry logging
    Logger.add_backend(Sentry.LoggerBackend)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Uneebee.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    UneebeeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
