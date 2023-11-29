defmodule Uneebee.Repo.Migrations.AddDurationToUserLessons do
  use Ecto.Migration

  def change do
    alter table(:user_lessons) do
      add :duration, :integer, null: false, default: 0
    end
  end
end
