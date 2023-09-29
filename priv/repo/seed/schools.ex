defmodule SchoolSeed do
  @moduledoc false

  alias Uneebee.Accounts
  alias Uneebee.Organizations

  @schools [
    %{
      name: "UneeBee",
      custom_domain: "uneebee.test",
      email: "noreply@uneebee.com",
      logo: "/uploads/seed/schools/uneebee.png",
      public?: true,
      slug: "uneebee",
      managers: ["einstein"],
      teachers: ["curie", "newton"],
      students: ["lovelace", "tesla", "franklin", "pasteur", "davinci", "goodall"]
    }
  ]

  @doc """
  Seeds the database with schools.
  """
  def seed do
    Enum.each(@schools, fn attrs ->
      manager = Accounts.get_user_by_username(Enum.at(attrs.managers, 0))
      attrs = Map.merge(attrs, %{created_by_id: manager.id})
      {:ok, school} = Organizations.create_school(attrs)
      create_school_users(school, attrs)
    end)
  end

  defp create_school_users(school, attrs) do
    Enum.each(attrs.managers, fn manager -> create_school_user(school, manager, :manager) end)
    Enum.each(attrs.teachers, fn teacher -> create_school_user(school, teacher, :teacher) end)
    Enum.each(attrs.students, fn student -> create_school_user(school, student, :student) end)
  end

  defp create_school_user(school, username, role) do
    user = Accounts.get_user_by_username(username)
    Organizations.create_school_user(school, user, school_user_attrs(user, role))
  end

  defp school_user_attrs(user, role) do
    %{role: role, approved?: true, approved_by_id: user.id, approved_at: DateTime.utc_now()}
  end
end
