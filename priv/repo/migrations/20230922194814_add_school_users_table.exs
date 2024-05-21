defmodule Zoonk.Repo.Migrations.AddSchoolUsersTable do
  use Ecto.Migration

  def change do
    create table(:school_users) do
      add :approved?, :boolean, default: false, null: false
      add :approved_at, :utc_datetime_usec
      add :approved_by_id, references(:users, on_delete: :nothing)
      add :role, :string, default: "student", null: false
      add :school_id, references(:schools, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create constraint(:school_users, :valid_role,
             check: "role in ('manager', 'teacher', 'student')"
           )

    create index(:school_users, [:school_id])
    create index(:school_users, [:user_id])
    create index(:school_users, [:role, :school_id])
    create unique_index(:school_users, [:school_id, :user_id])
  end
end
