defmodule Uneebee.Repo.Migrations.AddStepSuggestedCoursesTable do
  use Ecto.Migration

  def change do
    create table(:step_suggested_courses) do
      add :lesson_step_id, references(:lesson_steps, on_delete: :delete_all), null: false
      add :course_id, references(:courses, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:step_suggested_courses, [:lesson_step_id, :course_id])
  end
end
