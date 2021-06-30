defmodule Stein.MixProject do
  use Mix.Project

  def project do
    [
      app: :stein,
      version: "0.5.4",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      source_url: "https://github.com/smartlogic/stein",
      homepage_url: "https://github.com/smartlogic/stein",
      description: description(),
      package: package(),
      docs: [
        main: "readme",
        extras: ["README.md"]
      ],
      deps: deps()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bcrypt_elixir, "~> 2.0"},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0", only: :test},
      {:elixir_uuid, "~> 1.2"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:postgrex, ">= 0.0.0", only: :test},
      {:timex, "~> 3.5"}
    ]
  end

  def description() do
    """
    Stein contains common helper functions to our projects at SmartLogic.
    """
  end

  def package() do
    [
      maintainers: ["Eric Oestrich"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/smartlogic/stein"},
      exclude_patterns: [~r/priv\/repo/]
    ]
  end
end
