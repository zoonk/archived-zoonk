defmodule Uneebee.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  alias Uneebee.Accounts.User
  alias Uneebee.Accounts.UserNotifier
  alias Uneebee.Accounts.UserToken
  alias Uneebee.Gamification
  alias Uneebee.Mailer
  alias Uneebee.Organizations.School
  alias Uneebee.Repo
  alias UneebeeWeb.Shared.Utilities

  @type user_changeset :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  @spec get_user_by_email(String.t()) :: User.t() | nil
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  @spec get_user_by_email_and_password(String.t(), String.t()) :: User.t() | nil
  def get_user_by_email_and_password(email, password) when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a user by username.

  ## Examples

      iex> get_user_by_username("mariecurie")
      %User{}

      iex> get_user_by_username("unknown")
      nil

  """
  @spec get_user_by_username(String.t()) :: User.t() | nil
  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username)
  end

  @doc """
  Gets a user by either their email address or username.

  ## Examples

      iex> get_user_by_email_or_username("foo@example.com")
      %User{}

      iex> get_user_by_username("davinci")
      %User{}

  """
  @spec get_user_by_email_or_username(String.t()) :: User.t() | nil
  def get_user_by_email_or_username(email_or_username) do
    if String.contains?(email_or_username, "@") do
      get_user_by_email(email_or_username)
    else
      get_user_by_username(email_or_username)
    end
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_or_username_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_or_username_and_password("adalovelace", "correct_password")
      %User{}

      iex> get_user_by_email_or_username_and_password("foo@example.com", "invalid_password")
      nil

  """
  @spec get_user_by_email_or_username_and_password(String.t(), String.t()) :: User.t() | nil
  def get_user_by_email_or_username_and_password(email_or_username, password) when is_binary(email_or_username) and is_binary(password) do
    user = get_user_by_email_or_username(email_or_username)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_user!(integer()) :: User.t()
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Deletes a user account.

  ## Examples

      iex> delete_user!(user)
      {:ok, %User{}}

  """
  @spec delete_user(User.t()) :: user_changeset()
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec register_user(map()) :: user_changeset()
  def register_user(attrs) do
    %User{} |> User.registration_changeset(attrs) |> Repo.insert()
  end

  @doc """
  Creates a guest user.

  This is a temporary user that is created when a user is not logged in.
  This is useful to allow users to play courses without having to register.

  ## Examples

      iex> create_guest_user()
      {:ok, %User{}}
  """
  @spec create_guest_user() :: user_changeset()
  def create_guest_user do
    timestamp = System.os_time(:millisecond)
    str = 3 |> :crypto.strong_rand_bytes() |> Base.url_encode64()
    username = "#{str}_#{timestamp}"
    email = "#{username}@example.com"
    password = Utilities.generate_password()

    %User{} |> User.registration_changeset(%{email: email, password: password, username: username, guest?: true}) |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  @spec change_user_registration(User.t(), map()) :: Ecto.Changeset.t()
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user settings.

  ## Examples

      iex> change_user_settings(user)
      %Ecto.Changeset{data: %User{}}

  """
  @spec change_user_settings(User.t(), map()) :: Ecto.Changeset.t()
  def change_user_settings(user, attrs \\ %{}) do
    User.settings_changeset(user, attrs)
  end

  @doc """
  Updates the user settings.

  ## Examples

      iex> update_user_settings(user, %{username: ...})
      {:ok, %User{}}

      iex> update_user_settings(user, %{username: ...})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_user_settings(User.t(), map()) :: user_changeset
  def update_user_settings(%User{} = user, attrs \\ %{}) do
    changeset = change_user_settings(user, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.run(:mission, fn _repo, %{user: user} -> Gamification.complete_user_mission(user, :profile) end)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _error} -> {:error, changeset}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  @spec change_user_email(User.t(), map()) :: Ecto.Changeset.t()
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  @spec apply_user_email(User.t(), String.t(), map()) :: user_changeset
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> maybe_validate_current_password(user, password)
    |> Ecto.Changeset.apply_action(:update)
  end

  defp maybe_validate_current_password(changeset, %User{guest?: true}, _password), do: changeset
  defp maybe_validate_current_password(changeset, _user, password), do: User.validate_current_password(changeset, password)

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  @spec update_user_email(User.t(), String.t()) :: :ok | :error
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- user |> user_email_multi(email, context) |> Repo.transaction() do
      :ok
    else
      _error -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm_email/#{&1})")
      {:ok, %{to: ..., body: ...}}

  """
  @spec deliver_user_update_email_instructions(User.t(), School.t() | nil, String.t(), (String.t() -> String.t())) ::
          Mailer.t()
  def deliver_user_update_email_instructions(%User{} = user, school, current_email, update_email_url_fun) when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(school, user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  @spec change_user_password(User.t(), map()) :: Ecto.Changeset.t()
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_user_password(User.t(), String.t(), map()) :: user_changeset
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _error} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  @spec generate_user_session_token(User.t()) :: String.t()
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  @spec get_user_by_session_token(String.t()) :: User.t() | nil
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  @spec delete_user_session_token(String.t()) :: :ok
  def delete_user_session_token(token) do
    token |> UserToken.token_and_context_query("session") |> Repo.delete_all()
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &url(~p"/users/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  @spec deliver_user_confirmation_instructions(User.t(), School.t() | nil, (String.t() -> String.t())) :: Mailer.t() | {:error, :already_confirmed} | {:error, :not_required}
  def deliver_user_confirmation_instructions(_user, %School{require_confirmation?: false}, _url), do: {:error, :not_required}

  def deliver_user_confirmation_instructions(%User{} = user, school, confirmation_url_fun) when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)

      UserNotifier.deliver_confirmation_instructions(school, user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  @spec confirm_user(binary() | User.t()) :: {:ok, User.t()} | :error
  def confirm_user(token) when is_binary(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- user |> confirm_user_multi() |> Repo.transaction() do
      {:ok, user}
    else
      _error -> :error
    end
  end

  # When the first user is registered, we want to automatically configure them without sending an email
  # because the school email address isn't configured yet.
  def confirm_user(%User{} = user) do
    user |> User.confirm_changeset() |> Repo.update()
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  @spec deliver_user_reset_password_instructions(User.t(), School.t() | nil, (String.t() -> String.t())) :: Mailer.t()
  def deliver_user_reset_password_instructions(%User{} = user, school, reset_password_url_fun) when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(school, user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  @spec get_user_by_reset_password_token(binary()) :: User.t() | nil
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _error -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  @spec reset_user_password(User.t(), map()) :: user_changeset
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _error} -> {:error, changeset}
    end
  end
end
