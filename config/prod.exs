# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.

import Config

# Do not print debug messages in production
config :logger, level: :info

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Req

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

config :zoonk, ZoonkWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"
config :zoonk, :csp, connect_src: System.get_env("CSP_CONNECT_SRC")
