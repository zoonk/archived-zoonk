defmodule Zoonk.Repo.Migrations.AddIndexToUserLessons do
  use Ecto.Migration

  def change do
    create index(:user_lessons, [:user_id, :inserted_at])
  end
end
