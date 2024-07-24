import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Jobs execute immediately within the calling process and without touching the database
config :zoonk, Oban, testing: :inline

# In test we don't send emails.
config :zoonk, Zoonk.Mailer, adapter: Swoosh.Adapters.Test

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
