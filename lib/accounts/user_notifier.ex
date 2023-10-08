defmodule Uneebee.Accounts.UserNotifier do
  @moduledoc false
  import Swoosh.Email
  import UneebeeWeb.Gettext

  alias Uneebee.Accounts.User
  alias Uneebee.Accounts.UserUtils
  alias Uneebee.Mailer
  alias Uneebee.Organizations.School

  @type deliver :: {:ok, Swoosh.Email.t()}

  # Delivers the email using the application mailer.
  @spec deliver(School.t() | nil, String.t(), String.t(), String.t()) :: deliver()
  defp deliver(school, recipient, subject, body) do
    school_name = get_school_name(school)
    school_email = get_school_email(school)

    email =
      new()
      |> to(recipient)
      |> from({school_name, school_email})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  @spec deliver_confirmation_instructions(School.t() | nil, User.t(), String.t()) :: deliver()
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

    deliver(school, user.email, subject, content)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  @spec deliver_reset_password_instructions(School.t() | nil, User.t(), String.t()) :: deliver()
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

    deliver(school, user.email, subject, content)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  @spec deliver_update_email_instructions(School.t() | nil, User.t(), String.t()) :: deliver()
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

    deliver(school, user.email, subject, content)
  end

  defp get_school_name(%School{name: name}), do: name
  defp get_school_name(_school), do: "UneeBee"

  defp get_school_email(%School{email: email}), do: email
  defp get_school_email(_school), do: "noreply@uneebee.com"
end
