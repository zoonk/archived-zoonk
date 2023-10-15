defmodule Uneebee.Repo.Migrations.RemoveKindFromLessonSteps do
  use Ecto.Migration

  def change do
    alter table(:lesson_steps) do
      remove :kind
      add :image, :string
    end
  end
end
