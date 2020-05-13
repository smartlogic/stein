defmodule Stein.Accounts do
  @moduledoc """
  Helper functions around user accounts

  To fully utilize the `Stein.Accounts` functions, your user schema struct
  should contain the following fields:

  ```elixir
  defmodule MyApp.Users.User do
    # ...

    schema "users" do
      field(:email, :string)
      field(:password, :string, virtual: true)
      field(:password_hash, :string)

      field(:email_verification_token, Ecto.UUID)
      field(:email_verified_at, :utc_datetime)

      field(:password_reset_token, Ecto.UUID)
      field(:password_reset_expires_at, :utc_datetime)
    end

    # ...
  end
  ```

  A sample Ecto migration:

  ```elixir
  def change() do
    create table(:users) do
      add(:email, :string)
      add(:password_hash, :string)

      add(:email_verification_token, :uuid)
      add(:email_verified_at, :utc_datetime)

      add(:password_reset_token, :uuid)
      add(:password_reset_expires_at, :utc_datetime)

      timestamps()
    end

    create index(:users, ["lower(email)"], unique: true)
  end
  ```
  """

  require Logger
  require Ecto.Query

  alias Ecto.Query
  alias Stein.Time

  @type email() :: String.t()

  @type password() :: String.t()

  @type password_hash() :: String.t()

  @type password_params() :: %{
          password: password(),
          password_confirmation: password()
        }

  @type reset_token() :: String.t()

  @type user() :: %{
          email: email(),
          password: password(),
          password_hash: password_hash(),
          email_verification_token: Stein.uuid(),
          email_verified_at: DateTime.t()
        }

  @type user_fun() :: (user() -> :ok)

  @type user_schema() :: atom()

  @doc """
  Find a user by their email address

  Trims and downcases the email to find an existing user. Checks against
  the `lower` unique index on their email that should be set up when using
  Stein.
  """
  def find_by_email(repo, schema, email) do
    email =
      email
      |> String.trim()
      |> String.downcase()

    query =
      schema
      |> Query.where([s], fragment("lower(?) = ?", s.email, ^email))
      |> Query.limit(1)

    case repo.one(query) do
      nil ->
        {:error, :not_found}

      user ->
        {:ok, user}
    end
  end

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
            hashed_password = Bcrypt.hash_pwd_salt(password)
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
  def validate_login(repo, schema, email, password) do
    case find_by_email(repo, schema, email) do
      {:error, :not_found} ->
        Bcrypt.no_user_verify()
        {:error, :invalid}

      {:ok, user} ->
        check_password(user, password)
    end
  end

  defp check_password(user, password) do
    case Bcrypt.verify_pass(password, user.password_hash) do
      true ->
        {:ok, user}

      false ->
        {:error, :invalid}
    end
  end

  @doc """
  Prepare a user for email validation

  This should run as part of the create changeset when registering a new user
  """
  @spec start_email_verification_changeset(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def start_email_verification_changeset(changeset) do
    changeset
    |> Ecto.Changeset.put_change(:email_verification_token, UUID.uuid4())
    |> Ecto.Changeset.put_change(:email_verified_at, nil)
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
            user
            |> Ecto.Changeset.change()
            |> Ecto.Changeset.put_change(:email_verified_at, Time.now())
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

  @doc """
  Start the password reset process

  On successful start of reset, the success function will be called. This can be
  used to send the password reset email.

  Requires the user schema to contain:
  - `password_reset_token`, type `:uuid`
  - `password_reset_expires_at`, type `utc_datetime`
  """
  @spec start_password_reset(Stein.repo(), user_schema(), email(), user_fun()) :: :ok
  def start_password_reset(repo, schema, email, success_fun \\ fn _user -> :ok end) do
    case find_by_email(repo, schema, email) do
      {:ok, user} ->
        expires_at = DateTime.add(Time.now(), 3600, :second)

        user
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_change(:password_reset_token, UUID.uuid4())
        |> Ecto.Changeset.put_change(:password_reset_expires_at, expires_at)
        |> repo.update()
        |> maybe_run_success(success_fun)

        :ok

      {:error, :not_found} ->
        :ok
    end
  end

  defp maybe_run_success({:ok, user}, success_fun), do: success_fun.(user)

  defp maybe_run_success(_, _), do: :ok

  @doc """
  Finish resetting a password

  Takes the token, checks for expiration, and then resets the password
  """
  @spec reset_password(Stein.repo(), user_schema(), reset_token(), password_params()) ::
          {:ok, user()} | {:error, Ecto.Changeset.t()}
  def reset_password(repo, struct, token, params) do
    with {:ok, uuid} <- Ecto.UUID.cast(token),
         {:ok, user} <- find_user_by_reset_token(repo, struct, uuid),
         {:ok, user} <- check_password_reset_expired(user) do
      user
      |> password_changeset(params)
      |> repo.update()
    end
  end

  defp find_user_by_reset_token(repo, struct, uuid) do
    case repo.get_by(struct, password_reset_token: uuid) do
      nil ->
        :error

      user ->
        {:ok, user}
    end
  end

  defp check_password_reset_expired(user) do
    case Time.after?(Time.now(), user.password_reset_expires_at) do
      true ->
        :error

      false ->
        {:ok, user}
    end
  end

  defp password_changeset(user, params) do
    user
    |> Ecto.Changeset.cast(params, [:password, :password_confirmation])
    |> Ecto.Changeset.validate_required([:password])
    |> Ecto.Changeset.validate_confirmation(:password)
    |> Ecto.Changeset.put_change(:password_reset_token, nil)
    |> Ecto.Changeset.put_change(:password_reset_expires_at, nil)
    |> hash_password()
    |> Ecto.Changeset.validate_required([:password_hash])
  end

  @doc """
  Trim a field in a changeset if present

  Calls `String.trim/1` on the field and replaces the value.
  """
  def trim_field(changeset, field) do
    case Ecto.Changeset.get_change(changeset, field) do
      nil ->
        changeset

      value ->
        Ecto.Changeset.put_change(changeset, field, String.trim(value))
    end
  end
end
