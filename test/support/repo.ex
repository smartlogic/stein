defmodule Stein.Repo do
  use Ecto.Repo,
    otp_app: :stein,
    adapter: Ecto.Adapters.Postgres
end
