defmodule Uneebee.Repo.Migrations.AddLessonsTable do
  use Ecto.Migration

  def change do
    create table(:lessons) do
      add :course_id, references(:courses, on_delete: :delete_all), null: false
      add :cover, :string
      add :description, :string, null: false
      add :kind, :string, default: "story", null: false
      add :name, :string, null: false
      add :order, :integer, null: false
      add :published?, :boolean, default: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:lessons, [:name])
  end
end
