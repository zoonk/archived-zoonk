defmodule Zoonk.Repo.Migrations.CreateSchoolObjects do
  use Ecto.Migration

  def change do
    create table(:school_objects) do
      add :key, :string
      add :content_type, :string
      add :size_kb, :integer
      add :school_id, references(:schools, on_delete: :delete_all)
      add :course_id, references(:courses, on_delete: :delete_all)
      add :lesson_id, references(:lessons, on_delete: :delete_all)
      add :lesson_step_id, references(:lesson_steps, on_delete: :delete_all)
      add :step_option_id, references(:step_options, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:school_objects, [:school_id])
    create index(:school_objects, [:course_id])
    create index(:school_objects, [:lesson_id])
    create index(:school_objects, [:lesson_step_id])
    create index(:school_objects, [:step_option_id])

    create unique_index(:school_objects, [:key])
  end
end
