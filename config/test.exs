use Mix.Config

config :bcrypt_elixir, :log_rounds, 4

config :logger, level: :error

config :stein, ecto_repos: [Stein.Repo]

config :stein, Stein.Repo,
  database: "stein_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
