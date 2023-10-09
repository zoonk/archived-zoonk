defmodule Uneebee.Accounts.UserNotifier do
  @moduledoc false
  import UneebeeWeb.Gettext

  alias Uneebee.Accounts.User
  alias Uneebee.Accounts.UserUtils
  alias Uneebee.Mailer
  alias Uneebee.Organizations.School

  @doc """
  Deliver instructions to confirm account.
  """
  @spec deliver_confirmation_instructions(School.t() | nil, User.t(), String.t()) :: Mailer.t()
  def deliver_confirmation_instructions(school, user, url) do
    subject = dgettext("mailer", "Confirmation instructions")

    content =
      dgettext(
        "mailer",
        """
        Hi %{name},

        You can confirm your account by visiting the URL below:

        %{url}

        If you didn't create an account with us, please ignore this.
        """,
        name: UserUtils.full_name(user),
        url: url
      )

    Mailer.send(school, user.email, subject, content)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  @spec deliver_reset_password_instructions(School.t() | nil, User.t(), String.t()) :: Mailer.t()
  def deliver_reset_password_instructions(school, user, url) do
    subject = dgettext("mailer", "Reset password instructions")

    content =
      dgettext(
        "mailer",
        """
        Hi %{name},

        You can reset your password by visiting the URL below:

        %{url}

        If you didn't request this change, please ignore this.
        """,
        name: UserUtils.full_name(user),
        url: url
      )

    Mailer.send(school, user.email, subject, content)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  @spec deliver_update_email_instructions(School.t() | nil, User.t(), String.t()) :: Mailer.t()
  def deliver_update_email_instructions(school, user, url) do
    subject = dgettext("mailer", "Update email instructions")

    content =
      dgettext(
        "mailer",
        """
        Hi %{name},

        You can change your email by visiting the URL below:

        %{url}

        If you didn't request this change, please ignore this.
        """,
        name: UserUtils.full_name(user),
        url: url
      )

    Mailer.send(school, user.email, subject, content)
  end
end
