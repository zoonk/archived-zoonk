defmodule Uneebee.Repo.Migrations.AddKindFieldToLessonSteps do
  use Ecto.Migration

  def change do
    alter table(:lesson_steps) do
      add :kind, :string, default: "quiz", null: false
    end
  end
end
