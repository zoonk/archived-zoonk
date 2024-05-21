defmodule Zoonk.Mailer do
  @moduledoc false
  use Swoosh.Mailer, otp_app: :zoonk

  import Swoosh.Email

  alias Zoonk.Mailer
  alias Zoonk.Organizations.School

  @type t :: {:ok, Swoosh.Email.t()} | {:error, any()}

  @doc """
  Delivers the email using the application mailer.
  """
  @spec send(School.t() | nil, String.t(), String.t(), String.t(), Keyword.t()) :: t()
  def send(school, recipient, subject, body, opts \\ []) do
    school_name = get_school_name(school)
    school_email = get_school_email(school)
    from_name = Keyword.get(opts, :from_name, school_name)
    from_email = Keyword.get(opts, :from_email, school_email)
    reply_name = Keyword.get(opts, :reply_name, from_name)
    reply_email = Keyword.get(opts, :reply_email, from_email)

    email =
      new()
      |> to(recipient)
      |> from({from_name, from_email})
      |> reply_to({reply_name, reply_email})
      |> subject(subject)
      |> text_body(body)

    case Mailer.deliver(email) do
      {:ok, _metadata} ->
        {:ok, email}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_school_name(%School{name: name}), do: name
  defp get_school_name(_school), do: "Zoonk"

  defp get_school_email(%School{email: email}), do: email
  defp get_school_email(_school), do: "noreply@zoonk.org"
end
