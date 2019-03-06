defmodule Stein.TestHelpers do
  @moduledoc false

  alias Stein.Repo
  alias Stein.Schemas.User

  def create_user() do
    %User{}
    |> User.changeset(%{email: "user@example.com", password: "password"})
    |> Repo.insert()
  end
end
