defmodule Uneebee.Support do
  @moduledoc """
  Support context.

  This module defines functions to be used on support pages.
  """
  import UneebeeWeb.Gettext

  alias Uneebee.Mailer
  alias Uneebee.Organizations.School

  @doc """
  Send a feedback message to the school support email.

  ## Examples

      iex> send_feedback(school, name, email, message)
      {:ok, mailer}
  """
  @spec send_feedback(School.t() | nil, String.t(), String.t(), String.t()) :: Mailer.t()
  def send_feedback(school, name, email, message) do
    subject = dgettext("mailer", "Feedback from %{name}", name: name)

    content =
      dgettext(
        "mailer",
        """
        Name: %{name}
        Email: %{email}

        %{message}
        """,
        name: name,
        email: email,
        message: message
      )

    Mailer.send(school, school.email, subject, content, reply_name: name, reply_email: email)
  end
end
