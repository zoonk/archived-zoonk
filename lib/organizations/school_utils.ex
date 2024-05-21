defmodule Zoonk.Organizations.SchoolUtils do
  @moduledoc """
  Reusable configuration and utilities for schools.
  """
  import ZoonkWeb.Gettext

  alias Zoonk.Organizations.SchoolUser

  @blocked_subdomains ["www", "mail", "smtp", "pop", "ftp", "api", "admin", "ns1", "ns2", "webmail", "autodiscover", "test", "localhost", "support"]

  @doc """
  Returns the list of supported roles for a school.
  """
  @spec roles() :: [{atom(), String.t()}]
  def roles do
    [
      manager: dgettext("orgs", "Manager"),
      teacher: dgettext("orgs", "Teacher"),
      student: dgettext("orgs", "Student")
    ]
  end

  @doc """
  Role options for displaying on a `select` component where the label is the key and the key is the value.
  """
  @spec role_options() :: [{String.t(), atom()}]
  def role_options do
    Enum.map(roles(), fn {key, value} -> {value, Atom.to_string(key)} end)
  end

  @doc """
  Returns the label for a given role.
  """
  @spec get_user_role(SchoolUser.t()) :: String.t()
  def get_user_role(%SchoolUser{} = school_user), do: Keyword.get(roles(), school_user.role)

  @doc """
  Remove a blocked subdomain from a given host.
  """
  @spec remove_blocked_subdomain(String.t()) :: String.t()
  def remove_blocked_subdomain(host) do
    String.replace(host, ~r/^(#{Enum.join(@blocked_subdomains, "|")})\./, "")
  end

  @doc """
  Returns a regex that validates a string doesn't contain any of the blocked subdomains.
  """
  @spec blocked_subdomain_regex() :: Regex.t()
  def blocked_subdomain_regex do
    blocked = Enum.join(@blocked_subdomains, "|")
    ~r/^(?!#{blocked})/
  end
end
