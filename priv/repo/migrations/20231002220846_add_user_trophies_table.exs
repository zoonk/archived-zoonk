defmodule Uneebee.Repo.Migrations.AddUserTrophiesTable do
  use Ecto.Migration

  def change do
    create table(:user_trophies) do
      add :reason, :string, null: false

      add :course_id, references(:courses, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime_usec)
    end

    create index(:user_trophies, [:user_id])
    create unique_index(:user_trophies, [:user_id, :course_id, :reason])
  end
end
