defmodule Uneebee.Fixtures.Organizations do
  @moduledoc """
  This module defines test helpers for creating entities via the `Uneebee.Organizations` context.
  """
  import Uneebee.Fixtures.Accounts

  alias Uneebee.Organizations
  alias Uneebee.Organizations.School

  defp unique_school_slug, do: "school-#{System.unique_integer()}"

  defp get_created_by_id do
    user = user_fixture()
    user.id
  end

  @doc """
  Generate a school with valid attributes.
  """
  @spec valid_school_attributes(map()) :: map()
  def valid_school_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      created_by_id: get_created_by_id(),
      email: "valid@email.com",
      public?: true,
      name: "some name",
      slug: unique_school_slug()
    })
  end

  @doc """
  Generate a school.
  """
  @spec school_fixture(map()) :: School.t()
  def school_fixture(attrs \\ %{}) do
    {:ok, %School{} = school} = attrs |> valid_school_attributes() |> Organizations.create_school()
    school
  end
end
