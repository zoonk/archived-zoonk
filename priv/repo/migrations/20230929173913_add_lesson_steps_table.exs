defmodule Zoonk.Repo.Migrations.AddLessonStepsTable do
  use Ecto.Migration

  def change do
    create table(:lesson_steps) do
      add :content, :string, null: false
      add :kind, :string, default: "text", null: false
      add :lesson_id, references(:lessons, on_delete: :delete_all), null: false
      add :order, :integer, null: false

      timestamps(type: :utc_datetime_usec)
    end
  end
end
