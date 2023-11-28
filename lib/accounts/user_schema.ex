defmodule Uneebee.Accounts.User do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset
  import UneebeeWeb.Gettext
  import UneebeeWeb.Shared.Validators

  alias UneebeeWeb.Plugs.Translate

  @type t() :: %__MODULE__{}

  schema "users" do
    field :avatar, :string
    field :confirmed_at, :naive_datetime
    field :date_of_birth, :date
    field :email, :string
    field :first_name, :string
    field :guest?, :boolean, default: false
    field :hashed_password, :string, redact: true
    field :language, Ecto.Enum, values: Translate.supported_locales(), default: :en
    field :last_name, :string
    field :password, :string, virtual: true, redact: true
    field :username, :string

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  @spec registration_changeset(Ecto.Schema.t(), map(), Keyword.t()) :: Ecto.Changeset.t()
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:avatar, :date_of_birth, :email, :first_name, :guest?, :language, :last_name, :password, :username])
    |> validate_user_email(opts)
    |> validate_password(opts)
    |> validate_username(opts)
    |> validate_settings()
  end

  defp validate_user_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_email(:email)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 72)
    |> validate_format(:password, ~r/[a-z]/, message: dgettext("errors", "at least one lower case character"))
    |> validate_format(:password, ~r/[A-Z]/, message: dgettext("errors", "at least one upper case character"))
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: dgettext("errors", "at least one digit or punctuation character"))
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Uneebee.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  @spec email_changeset(Ecto.Schema.t(), map(), Keyword.t()) :: Ecto.Changeset.t()
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_user_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, dgettext("errors", "did not change"))
    end
  end

  @doc """
  A user changeset for changing the username.
  """
  @spec settings_changeset(Ecto.Schema.t(), map(), Keyword.t()) :: Ecto.Changeset.t()
  def settings_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:avatar, :first_name, :last_name, :language, :username])
    |> validate_settings()
    |> validate_username(opts)
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  @spec password_changeset(Ecto.Schema.t(), map(), Keyword.t()) :: Ecto.Changeset.t()
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: dgettext("errors", "does not match password"))
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  @spec confirm_changeset(Ecto.Schema.t()) :: Ecto.Changeset.t()
  def confirm_changeset(user) do
    now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  @spec valid_password?(Ecto.Schema.t(), String.t()) :: boolean()
  def valid_password?(%Uneebee.Accounts.User{hashed_password: hashed_password}, password) when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_user, _password) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  @spec validate_current_password(Ecto.Changeset.t(), String.t()) :: Ecto.Changeset.t()
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, dgettext("errors", "is invalid"))
    end
  end

  defp validate_username(changeset, opts) do
    changeset
    |> validate_required([:username])
    |> validate_length(:username, min: 3, max: 30)
    |> validate_slug(:username)
    |> maybe_validate_unique_username(opts)
  end

  defp maybe_validate_unique_username(changeset, opts) do
    if Keyword.get(opts, :validate_username, true) do
      changeset |> unsafe_validate_unique(:username, Uneebee.Repo) |> unique_constraint(:username)
    else
      changeset
    end
  end

  defp validate_settings(changeset) do
    validate_required(changeset, [:language])
  end
end
