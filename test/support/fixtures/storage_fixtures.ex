defmodule Zoonk.Fixtures.Storage do
  @moduledoc """
  This module defines test helpers for creating entities via the `Zoonk.Storage` context.
  """

  import Zoonk.Fixtures.Organizations

  alias Zoonk.Storage
  alias Zoonk.Storage.SchoolObject

  @doc """
  Get valid attributes for a school object
  """
  @spec valid_school_object_attrs(map()) :: map()
  def valid_school_object_attrs(attrs \\ %{}) do
    school = Map.get(attrs, :school, school_fixture())

    Enum.into(attrs, %{
      key: "#{System.unique_integer()}.webp",
      content_type: "image/webp",
      size_kb: 100,
      school_id: school.id
    })
  end

  @doc """
  Generate a school object
  """
  @spec school_object_fixture(map()) :: SchoolObject.t()
  def school_object_fixture(attrs \\ %{}) do
    {:ok, school_object} = attrs |> valid_school_object_attrs() |> Storage.create_school_object()
    school_object
  end
end
