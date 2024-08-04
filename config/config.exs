# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.21.5",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/audios/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.4",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Oban config
config :zoonk, Oban,
  engine: Oban.Engines.Basic,
  repo: Zoonk.Repo,
  queues: [default: 10],
  shutdown_grace_period: :timer.seconds(60),
  plugins: [
    # Delete jobs after 7 days
    {Oban.Plugins.Pruner, max_age: 60 * 60 * 24 * 7},
    # Automatically move failed jobs back to available so they can run again
    {Oban.Plugins.Lifeline, rescue_after: :timer.minutes(30)}
  ]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :zoonk, Zoonk.Mailer, adapter: Swoosh.Adapters.Local

# Configures the endpoint
config :zoonk, ZoonkWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: ZoonkWeb.ErrorHTML, json: ZoonkWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Zoonk.PubSub,
  live_view: [signing_salt: "18a5Hr6d"]

# Configure translation
config :zoonk, ZoonkWeb.Gettext, default_locale: "en", locales: ~w(de en pt zh_TW)

# Content security policy
config :zoonk, :csp, connect_src: System.get_env("CSP_CONNECT_SRC")

# Storage config
config :zoonk, :storage,
  bucket: System.get_env("BUCKET_NAME"),
  domain: System.get_env("AWS_CDN_URL") || System.get_env("AWS_ENDPOINT_URL_S3")

config :zoonk,
  ecto_repos: [Zoonk.Repo],
  generators: [timestamp_type: :utc_datetime_usec]

if Mix.env() == :dev do
  config :mix_test_watch,
    tasks: ["test", "credo --strict"],
    clear: true
end

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
