defmodule Stein.TestHelpers do
  @moduledoc false

  alias Stein.Repo
  alias Stein.Schemas.User

  def create_user(attributes \\ %{}) do
    attributes =
      Map.merge(
        %{
          email: "user@example.com",
          password: "password"
        },
        attributes
      )

    %User{}
    |> User.changeset(attributes)
    |> Repo.insert()
  end
end
