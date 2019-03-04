ExUnit.start()

Stein.Repo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(Stein.Repo, :manual)
