defmodule Uneebee.MixProject do
  use Mix.Project

  def project do
    [
      app: :uneebee,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mix],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Uneebee.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:aws_signature, "~> 0.3.1"},
      {:bcrypt_elixir, "~> 3.0"},
      {:credo, "~> 1.7.3", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4.3", only: [:dev, :test], runtime: false},
      {:ecto_sql, "~> 3.11.1"},
      {:esbuild, "~> 0.8.1", runtime: Mix.env() == :dev},
      {:finch, "~> 0.17"},
      {:floki, "~> 0.35.3", only: :test},
      {:gettext, "~> 0.24.0"},
      {:hackney, "~> 1.20.1"},
      {:jason, "~> 1.2"},
      {:mix_audit, "~> 2.1.2", only: [:dev, :test], runtime: false},
      {:multipart, "~> 0.4.0"},
      {:mock, "~> 0.3.0", only: :test},
      {:money, "~> 1.12.4"},
      {:phoenix_ecto, "~> 4.4.3"},
      {:phoenix_html, "~> 4.0.0"},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.4"},
      {:phoenix, "~> 1.7.11"},
      {:plug_cowboy, "~> 2.7"},
      {:postgrex, "~> 0.17.4"},
      {:req, "~> 0.4.8"},
      {:resend, "~> 0.4.1"},
      {:sentry, "~> 10.1.0"},
      {:sobelow, "~> 0.13.0", only: [:dev, :test], runtime: false},
      {:stripity_stripe, "~> 3.1.1"},
      {:styler, "~> 0.11.9", only: [:dev, :test], runtime: false},
      {:swoosh, "~> 1.15.1"},
      {:tailwind, "~> 0.2.2", runtime: Mix.env() == :dev},
      {:tailwind_formatter, "~> 0.4.0", only: [:dev, :test], runtime: false},
      {:telemetry_metrics, "~> 0.6.2"},
      {:telemetry_poller, "~> 1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      seed: ["run priv/repo/seeds.exs"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"],
      icons: ["icons"],
      locale: ["gettext.extract", "gettext.merge priv/gettext"],
      ci: [
        "compile --all-warnings --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "sobelow -i Config.HTTPS --skip --exit",
        "deps.audit",
        "dialyzer"
      ]
    ]
  end
end
