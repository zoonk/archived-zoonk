defmodule Uneebee.Repo.Migrations.UpdateCourseDescriptionType do
  use Ecto.Migration

  def change do
    alter table(:courses) do
      modify :description, :text
    end
  end
end
