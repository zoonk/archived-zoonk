defmodule Uneebee.Repo.Migrations.RemoveAttemptsAndUniqueConstraintFromUserLesson do
  use Ecto.Migration

  def change do
    drop unique_index(:user_lessons, [:user_id, :lesson_id])
  end
end
