defmodule SchoolSeed do
  @moduledoc false

  alias Uneebee.Accounts
  alias Uneebee.Organizations

  @app %{
    name: "UneeBee",
    custom_domain: "uneebee.test",
    email: "noreply@uneebee.com",
    public?: true,
    slug: "uneebee",
    managers: ["einstein"],
    teachers: ["curie"],
    students: ["newton"]
  }

  @schools [
    %{
      name: "Apple",
      custom_domain: "apple.test",
      email: "noreply@example.com",
      public?: true,
      slug: "apple",
      managers: ["lovelace"],
      teachers: ["tesla"],
      students: ["franklin"]
    },
    %{
      name: "Google",
      custom_domain: nil,
      email: "noreply@example.com",
      public?: false,
      slug: "google",
      managers: ["pasteur"],
      teachers: ["davinci"],
      students: ["goodall"]
    }
  ]

  @doc """
  Seeds the database with schools.
  """
  def seed(args \\ %{}) do
    kind = Map.get(args, :kind, :white_label)
    multiple? = Map.get(args, :multiple?, false)

    app = create_app(kind)

    if kind != :white_label do
      schools = generate_school_attrs(multiple?)
      Enum.each(schools, fn attrs -> create_school(attrs, app) end)
    end
  end

  defp generate_school_attrs(false), do: @schools
  defp generate_school_attrs(true), do: generate_school_attrs()

  defp generate_school_attrs() do
    random_schools =
      Enum.map(1..30, fn idx ->
        %{
          name: "School #{idx}",
          custom_domain: nil,
          email: "noreply@example.com",
          public?: false,
          slug: "school-#{idx}",
          managers: ["lovelace"],
          teachers: ["tesla"],
          students: ["franklin"]
        }
      end)

    @schools ++ random_schools
  end

  defp create_school(attrs, app) do
    manager = Accounts.get_user_by_username(Enum.at(attrs.managers, 0))
    attrs = Map.merge(attrs, %{created_by_id: manager.id, school_id: app.id})
    {:ok, school} = Organizations.create_school(attrs)
    create_school_users(school, attrs)
  end

  defp create_app(kind) do
    manager = Accounts.get_user_by_username(Enum.at(@app.managers, 0))
    attrs = Map.merge(@app, %{created_by_id: manager.id, kind: kind})
    {:ok, school} = Organizations.create_school(attrs)
    create_school_users(school, attrs)
    school
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
