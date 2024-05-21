defmodule Zoonk.Repo.Migrations.AddCourseUsersTable do
  use Ecto.Migration

  def change do
    create table(:course_users) do
      add :approved?, :boolean
      add :approved_at, :utc_datetime_usec
      add :approved_by_id, references(:users, on_delete: :delete_all)
      add :role, :string, default: "student", null: false
      add :course_id, references(:courses, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create constraint(:course_users, :valid_role, check: "role in ('teacher', 'student')")

    create index(:course_users, [:course_id])
    create index(:course_users, [:user_id])

    create unique_index(:course_users, [:course_id, :user_id])
  end
end
