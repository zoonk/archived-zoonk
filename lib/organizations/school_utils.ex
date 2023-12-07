defmodule Uneebee.Organizations.SchoolUtils do
  @moduledoc """
  Reusable configuration and utilities for schools.
  """
  import UneebeeWeb.Gettext

  alias Uneebee.Organizations.SchoolUser

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
end
