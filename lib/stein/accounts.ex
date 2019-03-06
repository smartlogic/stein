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
            hashed_password = Comeonin.Bcrypt.hashpwsalt(password)
            Ecto.Changeset.put_change(changeset, :password_hash, hashed_password)
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

  @doc """
  Verify an email is valid from the token
  """
  def verify_email(repo, struct, token) do
    case Ecto.UUID.cast(token) do
      {:ok, token} ->
        case repo.get_by(struct, email_verification_token: token) do
          nil ->
            {:error, :invalid}

          user ->
            verified_at = DateTime.truncate(Timex.now(), :second)

            user
            |> Ecto.Changeset.change()
            |> Ecto.Changeset.put_change(:email_verified_at, verified_at)
            |> Ecto.Changeset.put_change(:email_verification_token, nil)
            |> repo.update()
        end

      :error ->
        {:error, :invalid}
    end
  end

  @doc """
  Check if the user's email has been verified

      iex> user = %User{email_verified_at: Timex.now()}
      iex> Accounts.email_verified?(user)
      true

      iex> user = %User{}
      iex> Accounts.email_verified?(user)
      false
  """
  def email_verified?(%{email_verified_at: verified_at}) when verified_at != nil, do: true

  def email_verified?(_), do: false
end
