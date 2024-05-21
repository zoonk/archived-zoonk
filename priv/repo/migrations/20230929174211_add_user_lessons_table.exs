defmodule Zoonk.Repo.Migrations.AddUserLessonsTable do
  use Ecto.Migration

  def change do
    create table(:user_lessons) do
      add :attempts, :integer, default: 0
      add :correct, :integer, default: 0
      add :total, :integer, default: 0

      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :lesson_id, references(:lessons, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:user_lessons, [:user_id, :lesson_id])
  end
end
