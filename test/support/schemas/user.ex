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
    field(:password_confirmation, :string, virtual: true)
    field(:password_hash, :string)
    field(:email_verification_token, :string)
    field(:email_verified_at, :utc_datetime)
    field(:password_reset_token, Ecto.UUID)
    field(:password_reset_expires_at, :utc_datetime)
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:email, :password])
    |> put_change(:email_verification_token, UUID.uuid4())
    |> Accounts.hash_password()
  end
end
