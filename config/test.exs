import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :zoonk, Zoonk.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "zoonk_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :zoonk, ZoonkWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "8K9cBY8N762b1KPu0OW/5vEmwdUQd1k/OPM7VXVm4bNH9ujtWOLZMaDiBhG/MtfS",
  server: false

# In test we don't send emails.
config :zoonk, Zoonk.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Stripe test keys
config :stripity_stripe,
  api_key: "sk_test_thisisaboguskey",
  webhook_secret: "whsec_thisisaboguskey",
  api_base_url: "http://localhost:12111"

config :stripity_stripe, :retries, max_attempts: 5, base_backoff: 500, max_backoff: 2_000
