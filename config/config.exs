# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :uneebee,
  ecto_repos: [Uneebee.Repo]

# Configures the endpoint
config :uneebee, UneebeeWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: UneebeeWeb.ErrorHTML, json: UneebeeWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Uneebee.PubSub,
  live_view: [signing_salt: "18a5Hr6d"]

# Cloud storage configuration
config :uneebee, :storage,
  bucket: System.get_env("STORAGE_BUCKET"),
  access_key_id: System.get_env("STORAGE_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("STORAGE_SECRET_ACCESS_KEY"),
  bucket_url: System.get_env("STORAGE_BUCKET_URL"),
  cdn_url: System.get_env("STORAGE_CDN_URL"),
  csp_connect_src: System.get_env("STORAGE_CSP_CONNECT_SRC")

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :uneebee, Uneebee.Mailer, adapter: Swoosh.Adapters.Local

# Configure translation
config :uneebee, UneebeeWeb.Gettext, default_locale: "en", locales: ~w(en pt)

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/audios/* --external:/images/* --external:/uploads/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
