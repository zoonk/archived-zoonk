import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/uneebee start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :uneebee, UneebeeWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_host =
    System.get_env("DATABASE_HOST") ||
      raise """
      environment variable DATABASE_HOST is missing.
      """

  config :uneebee, Uneebee.Repo,
    database: System.fetch_env!("DATABASE_NAME"),
    username: System.fetch_env!("DATABASE_USERNAME"),
    password: System.fetch_env!("DATABASE_PASSWORD"),
    hostname: database_host,
    ssl: true,
    ssl_opts: [
      cacertfile: System.fetch_env!("CERT_PATH"),
      server_name_indication: to_charlist(database_host),
      verify: :verify_peer,
      customize_hostname_check: [
        # By default, Erlang does not support wildcard certificates. This function supports validating wildcard hosts
        match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
      ]
    ]

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :uneebee, UneebeeWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your endpoint, ensuring
  # no data is ever sent via http, always redirecting to https:
  #
  #     config :uneebee, UneebeeWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
  host = System.get_env("PHX_HOST") || "app.uneebee.com"
  port = String.to_integer(System.get_env("PORT") || "8080")

  config :uneebee, UneebeeWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  ## Configuring the mailer
  config :uneebee, Uneebee.Mailer,
    adapter: Resend.Swoosh.Adapter,
    api_key: System.get_env("RESEND_API_KEY")

  # Cloud storage configuration
  config :uneebee, :storage,
    bucket: System.get_env("STORAGE_BUCKET"),
    access_key_id: System.get_env("STORAGE_ACCESS_KEY_ID"),
    secret_access_key: System.get_env("STORAGE_SECRET_ACCESS_KEY"),
    bucket_url: System.get_env("STORAGE_BUCKET_URL")
end
