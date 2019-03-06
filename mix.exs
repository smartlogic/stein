defmodule Stein.MixProject do
  use Mix.Project

  def project do
    [
      app: :stein,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      source_url: "https://github.com/smartlogic/stein",
      homepage_url: "https://github.com/smartlogic/stein",
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
      {:bcrypt_elixir, "~> 1.0"},
      {:comeonin, "~> 4.0"},
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0", only: :test},
      {:elixir_uuid, "~> 1.2", only: :test},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:postgrex, ">= 0.0.0", only: :test},
      {:timex, "~> 3.5"},
    ]
  end
end
