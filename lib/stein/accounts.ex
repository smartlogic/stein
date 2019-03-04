defmodule Stein.Accounts do
  @moduledoc """
  Helper functions around user accounts
  """

  @doc """
  Hash the changed password in a changeset

  - Skips if the changeset is invalid
  - Skips if a password is not changed
  """
  def hash_password(changeset) do
    case changeset.valid? do
      true ->
        password = Ecto.Changeset.get_change(changeset, :password)

        case is_nil(password) do
          true ->
            changeset

          false ->
            Ecto.Changeset.put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(password))
        end

      false ->
        changeset
    end
  end

  @doc """
  Validate a login
  """
  def validate_login(repo, struct, email, password) do
    case repo.get_by(struct, email: email) do
      nil ->
        Comeonin.Bcrypt.dummy_checkpw()
        {:error, :invalid}

      user ->
        check_password(user, password)
    end
  end

  defp check_password(user, password) do
    case Comeonin.Bcrypt.checkpw(password, user.password_hash) do
      true ->
        {:ok, user}

      false ->
        {:error, :invalid}
    end
  end
end
