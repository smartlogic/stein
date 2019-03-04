defmodule Stein.Schemas.User do
  @moduledoc """
  User test schema
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Stein.Accounts

  schema "users" do
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:password_hash, :string)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:email, :password])
    |> Accounts.hash_password()
  end
end
