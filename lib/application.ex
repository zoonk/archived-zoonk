defmodule Zoonk.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ZoonkWeb.Telemetry,
      # Start the Ecto repository
      Zoonk.Repo,
      {DNSCluster, query: Application.get_env(:zoonk, :dns_cluster_query) || :ignore},
      # Start the PubSub system
      {Phoenix.PubSub, name: Zoonk.PubSub},
      # Start Finch
      {Finch, name: Zoonk.Finch},
      # Start the Endpoint (http/https)
      ZoonkWeb.Endpoint
      # Start a worker by calling: Zoonk.Worker.start_link(arg)
      # {Zoonk.Worker, arg}
    ]

    # Sentry logging
    Logger.add_backend(Sentry.LoggerBackend)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Zoonk.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    ZoonkWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
