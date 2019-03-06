defmodule Stein.Accounts do
  @moduledoc """
  Helper functions around user accounts

  To fully utilize the `Stein.Accounts` functions, your user schema struct
  should contain the following fields:

  ```elixir
  schema "users" do
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:password_hash, :string)
    field(:email_verification_token, :string)
    field(:email_verified_at, :utc_datetime)
  end
  ```
  """

  @type user_schema() :: atom()

  @type email() :: String.t()

  @type password() :: String.t()

  @type password_hash() :: String.t()

  @type user() :: %{
          email: email(),
          password: password(),
          password_hash: password_hash(),
          email_verification_token: Stein.uuid(),
          email_verified_at: DateTime.t()
        }

  @doc """
  Hash the changed password in a changeset

  - Skips if the changeset is invalid
  - Skips if a password is not changed
  - Hashes the password with BCrypt otherwise

  Requires the user schema to contain:
  - `password`, type `:string`
  - `password_hash`, type `:string`
  """
  @spec hash_password(Ecto.Changeset.t()) :: Ecto.Changeset.t()
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
  Validate a email and password match a user

  Requires the user schema to contain:
  - `email`, type `:string`
  - `password_hash`, type `:string`
  """
  @spec validate_login(Stein.repo(), user_schema(), email(), password()) ::
          {:error, :invalid} | {:ok, user()}
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
  Verify a user's email address from a token sent to their email address

  This token should be a UUID, if it is not `{:error, :invalid}` will be returned.

  Requires the user schema to contain:
  - `email_verification_token`, type `:uuid`
  - `email_verified_at`, type `:utc_datetime`
  """
  @spec verify_email(Stein.repo(), user_schema(), Stein.uuid()) ::
          {:ok, user()} | {:error, :invalid} | {:error, Ecto.Changeset.t()}
  def verify_email(repo, struct, token) do
    case Ecto.UUID.cast(token) do
      {:ok, token} ->
        case repo.get_by(struct, email_verification_token: token) do
          nil ->
            {:error, :invalid}

          user ->
            verified_at =
              :os.system_time()
              |> DateTime.from_unix!(:native)
              |> DateTime.truncate(:second)

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
  @spec email_verified?(user()) :: boolean()
  def email_verified?(user)

  def email_verified?(%{email_verified_at: verified_at}) when verified_at != nil, do: true

  def email_verified?(_), do: false
end
