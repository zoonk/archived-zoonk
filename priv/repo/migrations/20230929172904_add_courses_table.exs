defmodule Uneebee.Repo.Migrations.AddCoursesTable do
  use Ecto.Migration

  def change do
    create table(:courses) do
      add :cover, :string
      add :description, :string, null: false
      add :language, :string, null: false
      add :level, :string, default: "beginner", null: false
      add :name, :string, null: false
      add :public?, :boolean, default: false, null: false
      add :published?, :boolean, default: false, null: false
      add :school_id, references(:schools, on_delete: :delete_all), null: false
      add :slug, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:courses, [:public?, :published?, :language])
    create index(:courses, [:school_id])
    create index(:courses, [:school_id, :public?, :published?])

    create unique_index(:courses, [:slug, :school_id])
  end
end
