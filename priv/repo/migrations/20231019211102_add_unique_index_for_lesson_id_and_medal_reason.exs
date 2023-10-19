defmodule Uneebee.Repo.Migrations.AddUniqueIndexForLessonIdAndMedalReason do
  use Ecto.Migration

  def change do
    create unique_index(:user_medals, [:user_id, :lesson_id, :reason])
  end
end
