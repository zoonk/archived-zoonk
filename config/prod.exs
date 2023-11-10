import Config

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: Uneebee.Finch

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# Do not print debug messages in production
config :logger, level: :info

config :uneebee, UneebeeWeb.Endpoint,
  url: [host: System.get_env("PHX_HOST"), port: System.get_env("PORT")],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :uneebee, :csp, connect_src: System.get_env("CSP_CONNECT_SRC")
config :uneebee, :cdn, url: System.get_env("CDN_URL")
config :uneebee, :plausible, domain: System.get_env("PLAUSIBLE_DOMAIN")

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
