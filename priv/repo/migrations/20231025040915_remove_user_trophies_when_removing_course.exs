defmodule Zoonk.Repo.Migrations.RemoveUserTrophiesWhenRemovingCourse do
  use Ecto.Migration

  def change do
    drop constraint("user_trophies", "user_trophies_course_id_fkey")

    alter table(:user_trophies) do
      modify :course_id, references(:courses, on_delete: :delete_all)
    end
  end
end
