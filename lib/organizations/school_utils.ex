defmodule Uneebee.Organizations.SchoolUtils do
  @moduledoc """
  Reusable configuration and utilities for schools.
  """
  import UneebeeWeb.Gettext

  alias Uneebee.Organizations.SchoolUser

  @doc """
  Returns the label for a given role.
  """
  @spec get_user_role(SchoolUser.t()) :: String.t()
  def get_user_role(%SchoolUser{role: :manager}), do: dgettext("orgs", "Manager")
  def get_user_role(%SchoolUser{role: :teacher}), do: dgettext("orgs", "Teacher")
  def get_user_role(%SchoolUser{role: :student}), do: dgettext("orgs", "Student")
end
