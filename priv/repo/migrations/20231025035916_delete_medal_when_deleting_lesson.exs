defmodule Zoonk.Repo.Migrations.DeleteMedalWhenDeletingLesson do
  use Ecto.Migration

  def change do
    drop constraint("user_medals", "user_medals_lesson_id_fkey")

    alter table(:user_medals) do
      modify :lesson_id, references(:lessons, on_delete: :delete_all)
    end
  end
end
