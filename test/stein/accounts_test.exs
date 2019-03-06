defmodule Stein.AccountsTest do
  use Stein.DataCase

  alias Stein.Accounts
  alias Stein.Schemas.User

  doctest Accounts

  describe "hashing a password" do
    test "valid changeset and contains a password to hash" do
      changeset = Ecto.Changeset.change(%Schemas.User{}, %{password: "password"})

      changeset = Accounts.hash_password(changeset)

      assert changeset.changes[:password_hash]
    end

    test "ignores invalid changesets" do
      changeset = Ecto.Changeset.change(%Schemas.User{}, %{password: "password"})
      changeset = Ecto.Changeset.add_error(changeset, :base, "invalid")

      changeset = Accounts.hash_password(changeset)

      refute changeset.changes[:password_hash]
    end

    test "ignores changesets without a changed password" do
      changeset = Ecto.Changeset.change(%Schemas.User{}, %{})

      changeset = Accounts.hash_password(changeset)

      refute changeset.changes[:password_hash]
    end
  end

  describe "verifying a password" do
    test "correct password" do
      {:ok, user} = create_user()

      {:ok, found_user} = Accounts.validate_login(Repo, Schemas.User, user.email, "password")

      assert found_user.email == user.email
    end

    test "invalid email" do
      {:ok, _user} = create_user()

      {:error, :invalid} =
        Accounts.validate_login(Repo, Schemas.User, "unknown@example.com", "password")
    end

    test "invalid password" do
      {:ok, user} = create_user()

      {:error, :invalid} = Accounts.validate_login(Repo, Schemas.User, user.email, "password0")
    end
  end

  describe "validating an email address" do
    test "user found" do
      {:ok, user} = create_user()

      {:ok, user} = Accounts.verify_email(Repo, Schemas.User, user.email_verification_token)

      assert user.email_verified_at
    end

    test "reset the token with a valid token" do
      {:ok, user} = create_user()

      {:ok, user} = Accounts.verify_email(Repo, Schemas.User, user.email_verification_token)

      refute user.email_verification_token
    end

    test "token does not exist" do
      {:error, :invalid} = Accounts.verify_email(Repo, Schemas.User, UUID.uuid4())
    end

    test "token is not a uuid" do
      {:error, :invalid} = Accounts.verify_email(Repo, Schemas.User, "invalid")
    end
  end
end
