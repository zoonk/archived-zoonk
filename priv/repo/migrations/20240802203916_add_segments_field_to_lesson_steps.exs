defmodule Zoonk.Repo.Migrations.AddSegmentsFieldToLessonSteps do
  use Ecto.Migration

  def change do
    alter table(:lesson_steps) do
      add :segments, {:array, :text}
      # fill in the blank steps will have `segments` instead of `content`
      modify :content, :text, null: true
    end
  end
end
