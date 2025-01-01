defmodule Zoonk.MixProject do
  use Mix.Project

  def project do
    [
      app: :zoonk,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mix],
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_core_path: "priv/plts/core.plt",
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Zoonk.Application, []},
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
      {:bandit, "~> 1.6.1"},
      {:bcrypt_elixir, "~> 3.0"},
      {:credo, "~> 1.7.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4.3", only: [:dev, :test], runtime: false},
      {:dns_cluster, "~> 0.1.3"},
      {:ecto_sql, "~> 3.11.3"},
      {:esbuild, "~> 0.8.1", runtime: Mix.env() == :dev},
      {:ex_aws, "~> 2.5.4"},
      {:ex_aws_s3, "~> 2.5.3"},
      {:flame, "~> 0.5.2"},
      {:floki, "~> 0.36.2", only: :test},
      {:gettext, "~> 0.26.2"},
      {:hackney, "~> 1.20.1"},
      {:image, "~> 0.55.2"},
      {:jason, "~> 1.2"},
      {:mix_audit, "~> 2.1.2", only: [:dev, :test], runtime: false},
      {:mix_test_watch, "~> 1.2.0", only: [:dev, :test]},
      {:money, "~> 1.13.1"},
      {:mox, "~> 1.1.0", only: :test},
      {:oban, "~> 2.18.0"},
      {:phoenix_ecto, "~> 4.6.1"},
      {:phoenix_html, "~> 4.2.0"},
      {:phoenix_live_dashboard, "~> 0.8.4"},
      {:phoenix_live_reload, "~> 1.5.1", only: :dev},
      {:phoenix_live_view, "~> 1.0.0-rc.6", override: true},
      {:phoenix, "~> 1.7.14"},
      {:postgrex, "~> 0.19.3"},
      {:req, "~> 0.5.1"},
      {:resend, "~> 0.4.2"},
      {:sentry, "~> 10.8.1"},
      {:sobelow, "~> 0.13.0", only: [:dev, :test], runtime: false},
      {:styler, "~> 1.0.0-rc.2", only: [:dev, :test], runtime: false},
      # required by ex_aws_s3
      {:sweet_xml, "~> 0.7.4"},
      {:swoosh, "~> 1.16.9"},
      # Using the main branch instead of tags because of the size. Using the tag had over 1gb. Using a branch has less than 60mb.
      {:tabler_icons, github: "tabler/tabler-icons", branch: "main", sparse: "icons", app: false, compile: false, depth: 1},
      {:tailwind, "~> 0.2.3", runtime: Mix.env() == :dev},
      {:tailwind_formatter, "~> 0.4.0", only: [:dev, :test], runtime: false},
      {:telemetry_metrics, "~> 1.0.0"},
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
      locale: ["gettext.extract", "gettext.merge priv/gettext"],
      ci: [
        "compile --all-warnings --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "sobelow -i Config.HTTPS --skip --exit",
        "deps.audit",
        "deps.unlock --check-unused",
        "dialyzer"
      ]
    ]
  end
end
