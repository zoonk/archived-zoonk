import Config

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: Zoonk.Finch

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# Do not print debug messages in production
config :logger, level: :info

config :zoonk, ZoonkWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

config :zoonk, :csp, connect_src: System.get_env("CSP_CONNECT_SRC")
config :zoonk, :cdn, url: System.get_env("CDN_URL")

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
