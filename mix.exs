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
      ],

      # Docs
      name: "UneeBee",
      source_url: "https://github.com/zoonk/uneebee",
      homepage_url: "https://uneebee.com",
      docs: docs()
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
      {:bcrypt_elixir, "~> 3.0"},
      {:credo, "~> 1.7.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4.1", only: [:dev, :test], runtime: false},
      {:ecto_sql, "~> 3.10"},
      {:esbuild, "~> 0.7", runtime: Mix.env() == :dev},
      {:ex_doc, "~> 0.30.6", only: :dev, runtime: false},
      {:finch, "~> 0.13"},
      {:floki, ">= 0.30.0", only: :test},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:mix_audit, "~> 2.1.1", only: [:dev, :test], runtime: false},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_dashboard, "~> 0.8.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.0"},
      {:phoenix, "~> 1.7.7"},
      {:plug_cowboy, "~> 2.5"},
      {:postgrex, ">= 0.0.0"},
      {:sobelow, "~> 0.13.0", only: [:dev, :test], runtime: false},
      {:styler, "~> 0.9.3", only: [:dev, :test], runtime: false},
      {:swoosh, "~> 1.3"},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},
      {:tailwind_formatter, "~> 0.3.7", only: [:dev, :test], runtime: false},
      {:telemetry_metrics, "~> 0.6"},
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
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
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
        "sobelow --skip --exit",
        "deps.audit",
        "dialyzer"
      ]
    ]
  end

  defp docs do
    [
      main: "overview",
      logo: "priv/static/favicon/apple-touch-icon.png",
      extra_section: "GUIDES",
      formatters: ["html", "epub"],
      extras: extras(),
      groups_for_extras: groups_for_extras(),
      nest_modules_by_prefix: nest_modules_by_prefix()
    ]
  end

  defp extras do
    [
      "guides/introduction/overview.md",
      "guides/introduction/installation.md",
      "guides/introduction/ssl.md"
    ]
  end

  defp groups_for_extras do
    [
      Introduction: ~r/guides\/introduction\/.?/
    ]
  end

  defp nest_modules_by_prefix do
    [
      UneebeeWeb.Components
    ]
  end
end
