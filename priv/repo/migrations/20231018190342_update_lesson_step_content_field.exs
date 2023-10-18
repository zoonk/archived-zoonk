defmodule Uneebee.Repo.Migrations.UpdateLessonStepContentField do
  use Ecto.Migration

  def change do
    alter table(:lesson_steps) do
      modify :content, :text
    end
  end
end
